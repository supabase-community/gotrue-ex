# GoTrue

Elixir client for GoTrue, an authentication service that supports many methods of authentication.

- Email/password logins
- Passwordless logins with magic links
- OAUTH2 - Google, GitHub, BitBucket, GitLab, Facebook
- SAML (not yet implmented by this client)

[Documentation](https://hexdocs.pm/gotrue)

## Installation

Add `gotrue` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:gotrue, "~> 0.1.0"}
  ]
end
```

In your `config/dev.exs` & `config/prod.exs`, configure your GoTrue

```elixir
config :gotrue,
  base_url: "http://0.0.0.0:9999",
  access_token: "your-super-secret-operator-token"
```

# Usage

## Creating a user account

Several options exist to create an account

### Password based

Pass credentials to `GoTrue.sign_up/1`, it will create a new account and return back a JWT access token.

```elixir
GoTrue.sign_up(%{email: "user@example.com", password: "123456"})
```

### OAUTH 

Call `GoTrue.url_for_provider/1`, it returns a URL you can redirect the user to: 

```elixir
GoTrue.url_for_provider(:google)
GoTrue.url_for_provider(:github)
GoTrue.url_for_provider(:gitlab)
GoTrue.url_for_provider(:bitbucket)
GoTrue.url_for_provider(:facebook)
```

### Magic Link

User's can login without password by requesting a magic link:

```elixir
GoTrue.send_magic_link("user@example.com")
```

## Sign in

If you are using password logins, sign in by passing the `email` & `password` to `GoTrue.sign_in/1`, it returns a JWT

```elixir
GoTrue.sign_in(%{email: "user@example.com", password: "12345"})
```

## Refreshing JWT

The JWT expires based on your GoTrue server's settings. To refresh it, pass the `refresh_token` to `GoTrue.refresh_access_token/1`

```elixir
# first get an access token, there are many ways:

# via sign up
%{access_token: jwt, refresh_token: refresh_token} = GoTrue.sign_up(...)

# or via login
%{access_token: jwt, refresh_token: refresh_token} = GoTrue.sign_in(...)

# or via a redirection from an oauth provider
def controller_action(conn, %{access_token: jwt, refresh_token: refresh_token}) do
  # put in session
end

# refresh it before it expires
%{access_token: new_jwt, refresh_token: new_refresh_token} = GoTrue.refresh_access_token(refresh_token)
```

## Sign out

The JWT can be revoked, effectively signing out the user, by called `GoTrue.sign_out/1`

```elixir
GoTrue.sign_out(jwt)
```

## Get user info

Using a JWT the user data can be accessed by calling `GoTrue.get_user/1`

```elixir
GoTrue.get_user(jwt)
```

## Update user info

Using a JWT, user data can be updated by calling `GoTrue.update_user/1`

```elixir
GoTrue.update_user(jwt, %{data: %{favorite_language: "elixir"}})
```

## Invitations

User's can be invited by passing their email address to `GoTrue.invite/1`, this sends an email to the user with a link.

```elixir
GoTrue.invite(%{email: "user@example.com"})
```

## Settings

To view the server's auth settings, call `GoTrue.settings()`

# License

MIT
