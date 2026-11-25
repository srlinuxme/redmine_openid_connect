# frozen_string_literal: true

require 'doorkeeper'

module RedmineOpenidConnect
  # Optional OAuth2 provider (Authorization Code + PKCE + refresh tokens),
  # built on Doorkeeper like the Redmine 6.1 core (Feature #24808).
  #
  # A client application (e.g. an internal assistant) sends the user to
  # /oauth/authorize; the user signs in (through OpenID Connect, when enabled)
  # and approves the access on a Redmine page. The application then calls the
  # REST API with "Authorization: Bearer <token>" acting as that user.
  #
  # Deliberate difference from 6.1: there are no per-permission scopes. A token
  # is worth the same as the user's API key (their project permissions), never
  # administration, and it cannot change the account or read the API key.
  #
  # Off by default: enable it in the plugin settings.
  module OauthProvider
    SCOPE = 'api'
    LOOPBACK_HOSTS = %w[localhost 127.0.0.1 ::1].freeze

    module_function

    # Redmine 6.1+ ships its own OAuth2 provider (Feature #24808): then this
    # one stays out of the way entirely.
    def core_provider?
      Redmine::VERSION::MAJOR > 6 || (Redmine::VERSION::MAJOR == 6 && Redmine::VERSION::MINOR >= 1)
    end

    def enabled?
      return false if core_provider?

      settings = Setting.plugin_redmine_openid_connect
      settings.is_a?(Hash) && %w[1 true].include?(settings['oauth_provider_enabled'].to_s) &&
        Setting.rest_api_enabled?
    end

    def configure!
      Doorkeeper.configure do
        orm :active_record

        base_controller 'ApplicationController'
        realm 'Redmine'

        # Tokens are only issued after the user's consent.
        grant_flows %w[authorization_code]
        use_refresh_token
        force_pkce

        authorization_code_expires_in 10.minutes
        access_token_expires_in 2.hours

        # Header only: tokens in URLs end up in proxy logs.
        access_token_methods :from_bearer_authorization

        hash_token_secrets
        hash_application_secrets

        default_scopes RedmineOpenidConnect::OauthProvider::SCOPE
        enforce_configured_scopes
        allow_token_introspection false

        force_ssl_in_redirect_uri { |uri| !RedmineOpenidConnect::OauthProvider::LOOPBACK_HOSTS.include?(uri.host) }
        forbid_redirect_uri { |uri| %w[data vbscript javascript file].include?(uri.scheme.to_s.downcase) }

        # The resource owner is the signed-in Redmine user. With OpenID Connect
        # enabled, require_login sends the user to the SSO server and back here.
        resource_owner_authenticator do
          User.current if require_login
        end

        admin_authenticator do |_routes|
          require_admin
        end
      end
    end

    # Endpoints answer 404 while the feature is disabled.
    module Gate
      def self.included(base)
        base.prepend_before_action :oic_require_oauth_provider
      end

      private

      def oic_require_oauth_provider
        # Runs before Redmine's user_setup (and the token endpoint has none),
        # so refresh the settings cache here.
        Setting.check_cache
        head :not_found unless RedmineOpenidConnect::OauthProvider.enabled?
      end
    end

    def prepare_controllers!
      return if core_provider?

      [Doorkeeper::AuthorizationsController,
       Doorkeeper::TokensController,
       Doorkeeper::ApplicationsController,
       Doorkeeper::AuthorizedApplicationsController].each do |controller|
        controller.include(Gate) unless controller < Gate
      end

      Doorkeeper::ApplicationsController.layout 'admin'
      Doorkeeper::AuthorizationsController.layout 'base'
      Doorkeeper::AuthorizedApplicationsController.layout 'base'

      Doorkeeper::ApplicationsController.class_eval do
        require_sudo_mode :create, :show, :update, :destroy
      end

      Doorkeeper::AuthorizationsController.class_eval do
        require_sudo_mode :create, :destroy

        # Doorkeeper's render_error takes no argument, Redmine's takes one:
        # keep both working (Redmine #43698).
        unless method_defined?(:doorkeeper_render_error) || private_method_defined?(:doorkeeper_render_error)
          alias_method :doorkeeper_render_error, :render_error
          def render_error(arg = nil)
            arg ? super : doorkeeper_render_error
          end
        end
      end
    end

    # "Authorization: Bearer <token>" on REST API requests, like the 6.1 core.
    # An API key (X-Redmine-API-Key or ?key=) still takes precedence.
    module ApplicationControllerPatch
      BEARER = /\ABearer\s+\S/i.freeze

      def find_current_user
        return super unless oic_oauth_bearer_request?

        token = Doorkeeper.authenticate(request)
        unless token&.accessible? && token.acceptable?(RedmineOpenidConnect::OauthProvider::SCOPE)
          oic_oauth_invalid_token
          return nil
        end

        # Inactive owner: no access, no 500 (Redmine #44654).
        user = User.active.find_by(id: token.resource_owner_id)
        unless user
          oic_oauth_invalid_token
          return nil
        end

        user.oauth_scope = token.scopes.to_a.map(&:to_sym)
        user.remote_ip = request.remote_ip
        # No X-Redmine-Switch-User: an OAuth token is never admin (UserPatch).
        user
      end

      private

      def oic_oauth_bearer_request?
        api_request? &&
          RedmineOpenidConnect::OauthProvider.enabled? &&
          accept_api_auth? &&
          api_key_from_request.blank? &&
          BEARER.match?(request.authorization.to_s)
      end

      def oic_oauth_invalid_token
        response.headers['WWW-Authenticate'] =
          'Bearer realm="Redmine", error="invalid_token", error_description="The access token is invalid, expired or revoked."'
        head :unauthorized
      end
    end

    module UserPatch
      def self.prepended(base)
        base.class_eval do
          attr_writer :oauth_scope

          # Deleting a user deletes their grants and tokens (Redmine #44343).
          has_many :oauth_access_grants, class_name: 'Doorkeeper::AccessGrant',
                   foreign_key: :resource_owner_id, dependent: :delete_all
          has_many :oauth_access_tokens, class_name: 'Doorkeeper::AccessToken',
                   foreign_key: :resource_owner_id, dependent: :delete_all
        end
      end

      def authorized_by_oauth?
        !@oauth_scope.nil?
      end

      # An OAuth token never administrates Redmine, even when the user who
      # approved it is an administrator.
      def admin?
        return false if authorized_by_oauth?

        super
      end

      # Requests made with an OAuth token never see an API key (Redmine
      # #44174): GET /users/current.json and /my/account.json omit it.
      def api_key
        return nil if User.current.authorized_by_oauth?

        super
      end
    end

    # The account cannot be changed with a token: changing the email and asking
    # for a password reset would take the account over (Redmine #44174).
    module MyControllerPatch
      def self.prepended(base)
        base.before_action :oic_oauth_deny_account_modification, only: :account
      end

      private

      def oic_oauth_deny_account_modification
        render_403 if request.put? && User.current.authorized_by_oauth?
      end
    end
  end
end
