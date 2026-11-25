source 'https://rubygems.org'
gem 'httparty', '~> 0.14.0'
# Optional OAuth2 provider. 5.9 is the series used by the Redmine 6.1 core and
# still supports Ruby 2.7 / Rails 6.1.
# Redmine 6.1+ already requires it (and has its own provider).
gem 'doorkeeper', '~> 5.9.0' unless dependencies.any? { |d| d.name == 'doorkeeper' }
# ID token signature verification (JWKS)
gem 'jwt', '>= 2.7', '< 4'
