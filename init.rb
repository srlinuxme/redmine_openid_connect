require 'redmine'
require_relative 'lib/redmine_openid_connect/application_controller_patch'
require_relative 'lib/redmine_openid_connect/account_controller_patch'
require_relative 'lib/redmine_openid_connect/hooks'
require_relative 'lib/redmine_openid_connect/oauth_provider'

Redmine::Plugin.register :redmine_openid_connect do
  name 'Redmine Openid Connect plugin'
  author 'Alfonso Juan Dillera / Markus M. May / Leandro Barbosa'
  description 'OpenID Connect implementation for Redmine'
  version '1.1.0'
  url 'https://github.com/srlinuxme/redmine_openid_connect'
  author_url 'https://github.com/srlinuxme'

  settings :default => { 'empty' => true }, partial: 'settings/redmine_openid_connect_settings'

  menu :admin_menu, :oauth_applications,
       { controller: 'oic_oauth_applications', action: 'index' },
       caption: :label_oauth_application_plural,
       html: { class: 'icon icon-server-authentication' },
       if: proc { RedmineOpenidConnect::OauthProvider.enabled? },
       before: :plugins
end


ApplicationController.prepend(RedmineOpenidConnect::ApplicationControllerPatch)
AccountController.prepend(RedmineOpenidConnect::AccountControllerPatch)

unless RedmineOpenidConnect::OauthProvider.core_provider?
  RedmineOpenidConnect::OauthProvider.configure!
  ApplicationController.prepend(RedmineOpenidConnect::OauthProvider::ApplicationControllerPatch)
  User.prepend(RedmineOpenidConnect::OauthProvider::UserPatch)
  MyController.prepend(RedmineOpenidConnect::OauthProvider::MyControllerPatch)
  # Called directly: Redmine 5.1+ already runs init.rb inside to_prepare,
  # where a nested to_prepare block would never run.
  RedmineOpenidConnect::OauthProvider.prepare_controllers!
end
