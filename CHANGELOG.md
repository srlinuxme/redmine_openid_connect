# Changelog
## Unreleased
* Optional OAuth2 provider (Doorkeeper): applications use the REST API on behalf of a user after the user approves it on a Redmine page. Off by default; off on Redmine 6.1+, which has it in core
* Security: verify the ID token signature (provider JWKS, or the client secret for HS*), issuer, audience, expiry and nonce; the ID token now only comes from the token endpoint, never from the browser redirect
* Security: "Disable SSL validation" applies to the plugin's own calls only (it used to turn off TLS verification for every HTTParty call in the process)
* Fix: the Redmine admin flag is only synchronised when an admin group is configured (every SSO login used to remove it when the setting was blank)
* Fix: invalid state / ID token redirected to a method call instead of the logout page

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
