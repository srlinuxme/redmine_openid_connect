# Changelog
## 1.0.2
* Fix parse_token Base64 error, by using JWT gem instead of manual parsing
* Fix get_user_info! for response.body is a string, not a hash
* user - uses parse_token to get user info, instead of get_user_info! which is not working with some providers like keycloak

## 1.0.1
* Fix ERR_TOO_MANY_REDIRECTS, by clean up expired session

## 1.0.0
* Fix wrong target origin warn with extentions like metamask
* Fix problem with groups keycloak

## 0.9.5
* Pull server-side errors from locale files
* Log-messages/some less prominent errors hard-coded in English again 
* Do not render `rpiframe`, if OpenID config does not contain a `check_session_iframe`
* Some more documentation about setting up

## 0.9.4
* Support Redmine 4
* Upgrade deprecated calls

## 0.9.3
* fix problem with symbols vs. strings usage

## 0.9.2
* fix settings page
* move to github
* Avoid error if members_of is empty during check
* Add disable ssl validation
* Add protocol to hostname
