# frozen_string_literal: true

# OAuth application registry (admin only). The scope is always the single one
# that exists, and applications are confidential (have a secret) unless the
# admin unchecks it; public clients must use PKCE (force_pkce).
class OicOauthApplicationsController < Doorkeeper::ApplicationsController
  menu_item :oauth_applications

  private

  def application_params
    params[:doorkeeper_application] ||= {}
    params[:doorkeeper_application][:scopes] = RedmineOpenidConnect::OauthProvider::SCOPE
    params[:doorkeeper_application][:confidential] =
      params[:doorkeeper_application][:confidential] != '0'
    super
  end
end
