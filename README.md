# Redmine OpenID Connect Plugin #

Based on the work from [intelimina](https://bitbucket.org/intelimina/redmine_openid_connect) and [devopskube](https://github.com/devopskube).

## Introduction ##

This is a plugin based on the implementation of redmine_cas. 

It redirects to an SSO server bypassing the original Redmine login authentication using the SSO server authentication in its place.

## Important ##

User registration is implicit and cannot be disabled at the moment.

So your OpenID provider should probably provide unique endpoints for your needs.

Check out [FusionAuth](https://fusionauth.io/) for an excellent solution.

## Server Settings  ##

Just include `username` in the scope being sent and replied to the client app.

## Usage ##

### Configure Redmine ###

1. Go to your Redmine plugins directory.
2. Clone/copy this plugin.
3. Run `bundle install`
4. Run `bundle exec rake redmine:plugins:migrate RAILS_ENV=production`
5. Restart your server
6. Login as administrator and head over to the plugins page.
7. Open the configuration page for redmine openid connect plugin.
8. Fill in the details.

### Configure Your OpenID Provider ###

1. Go to your SSO server and add these urls as authorized redirect urls:
   * `https://<your-redmine-domain>/oic/local_login`
   * `https://<your-redmine-domain>/oic/local_logout`
2. Check the JWT Token generation. You need the following contents:
   * **`member_of`**: `String[]` of role/group names that your config maps to user properties like *is administrator* or *is authorized to log in*
   * **`user_name`**: `String` with the user's desired username (required for user creation), aliases: `nickname`, `preferred_username`
   * **`given_name`**: `String` with the user's first name (required for user creation)
   * **`family_name`**: `String` with the user's surname (required for user creation)
   * **`name`**: `String` with the user's full name (used as a fallback for first name and surname)
   * Should some of these fields be missing, try finding *Lambda* functions or *Generators* that allow you to customize the JWT Tokens issued
3. The ID token must be signed with a key published in the provider's `jwks_uri` (RS/PS/ES algorithms) or with the client secret (HS algorithms). The plugin checks its signature, issuer, audience (`client_id`), expiry and nonce, and refuses the login otherwise.

**Admins group:** when set, the Redmine administrator flag follows that group on every SSO login. When blank, the plugin does not touch the flag.

## Optional: OAuth2 provider (Redmine 4.2 – 6.0) ##

Besides signing users in, the plugin can make Redmine an **OAuth2 provider**, so other applications can use the REST API **on behalf of a user without asking for their API key**. The user approves the access on a Redmine page; Redmine 6.1 has the same feature in core ([#24808](https://www.redmine.org/issues/24808)), and on 6.1+ this part of the plugin turns itself off.

1. Enable the REST API (*Administration › Settings › API*).
2. Run `bundle install` and `bundle exec rake redmine:plugins:migrate RAILS_ENV=production` (adds the `oauth_*` tables), restart.
3. Check **OAuth2 provider** in the plugin settings.
4. Register the application in *Administration › OAuth applications* (name, redirect URIs). The secret is shown only once.

Flow: Authorization Code with PKCE and refresh tokens.

| Method | Path | |
|---|---|---|
| GET | `/oauth/authorize` | consent page (`response_type=code`, `client_id`, `redirect_uri`, `state`, `code_challenge`, `code_challenge_method=S256`) |
| POST | `/oauth/token` | `authorization_code` (with `code_verifier`) or `refresh_token` |
| POST | `/oauth/revoke` | revokes a token |
| GET | `/oauth/authorized_applications` | the user reviews and revokes access (also linked from *My account*) |

The application then calls the API with `Authorization: Bearer <access_token>`. Access tokens last 2 hours; tokens are only accepted in the header, never in the URL.

What a token can do: whatever the user can do through the API with their own API key, in their projects and with their roles. What it can't: administrate Redmine (`admin?` is false for OAuth requests, even for administrators, so `X-Redmine-Switch-User` is ignored), change the user's account (`PUT /my/account`) or read the API key. Unlike Redmine 6.1 there are no per-permission scopes: there is a single scope, `api`.

While the option is unchecked every `/oauth/*` endpoint answers 404 and `Bearer` headers are ignored.

Before upgrading to Redmine 6.1+, roll the tables back and register the applications again in the core screen:

```
bundle exec rake redmine:plugins:migrate NAME=redmine_openid_connect VERSION=1 RAILS_ENV=production
```

## In Case Your OpenID Provider Is Offline ##

If you enable the OpenId Connect plugin and your OpenId Connect Server is not reachable, but you still would like to login, you can use an additional parameter, to be able to login directly into redmine: 

```https://<your-redmine-domain>/login?local_login=true```

Enjoy!
