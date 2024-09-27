require 'redmine'
require_relative 'lib/redmine_openid_connect/application_controller_patch'
require_relative 'lib/redmine_openid_connect/account_controller_patch'
require_relative 'lib/redmine_openid_connect/hooks'

Redmine::Plugin.register :redmine_openid_connect do
  name 'Redmine Openid Connect plugin'
  author 'Alfonso Juan Dillera / Markus M. May / Leandro Barbosa'
  description 'OpenID Connect implementation for Redmine'
  version '1.0.0'
  url 'https://github.com/srlinuxme/redmine_openid_connect/tree/develop'
  author_url 'https://srlinux.me'

  settings :default => { 'empty' => true }, partial: 'settings/redmine_openid_connect_settings'
end


ApplicationController.prepend(RedmineOpenidConnect::ApplicationControllerPatch)
AccountController.prepend(RedmineOpenidConnect::AccountControllerPatch)
