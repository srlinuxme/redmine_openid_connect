# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

get 'oic/login', to: 'account#oic_login'
get 'oic/logout', to: 'account#oic_logout'
get 'oic/local_login', to: 'account#oic_local_login'
get 'oic/local_logout', to: 'account#oic_local_logout'
get 'oic/rpiframe', to: 'account#rpiframe'

# Optional OAuth2 provider (answers 404 while disabled in the plugin settings)
unless RedmineOpenidConnect::OauthProvider.core_provider?
  use_doorkeeper do
    controllers applications: 'oic_oauth_applications'
    skip_controllers :token_info
  end
end
