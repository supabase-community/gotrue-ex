# GoTrue

An Elixir client for GoTrue.

GoTrue is an open source authentication service that supports many methods of authentication:

- Classic email+password logins
- Passwordless logins with magic links
- OAUTH2 - Google, GitHub, BitBucket, GitLab, etc..
- SAML (not yet implmented by this client)

[Documentation](https://hexdocs.pm/gotrue)

# Why?

[GoTrue](https://github.com/netlify/gotrue) is a way of doing authentication by delagating the work to a separate service. It has a very slim HTTP API, so less code to maintain. It's also a polyglot auth solution.

It was developed by Netlify, though this version is being developed against the [supabase fork](https://github.com/supabase/gotrue)

For many apps, [`phx_gen_auth`](https://github.com/aaronrenner/phx_gen_auth) is a great solution, but it requires a bit more work to setup and adjust. It does mean inheriting a bunch of code. For a small team, or for quick experimentation, offloading a task like auth removes a big friction and reduces time to market.

It also makes it possibile to create an Elixir [supabase](https://supabase.io) client down the road.

## Installation

Add `gotrue` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:gotrue, "~> 0.1.0"}
  ]
end
```

In your `config/dev.exs` & `config/prod.exs`, configure settings: 

```elixir
config :gotrue,
  # URL to you GoTrue instance
  base_url: "http://0.0.0.0:9999",

  # secret access token
  access_token: "your-super-secret-operator-token"
```

# Usage

## Creating a user account

Several options exist to create an account:

### Password based

Pass credentials to `GoTrue.sign_up/1`, a new account will be created and a JWT token is returned.

```elixir
GoTrue.sign_up(%{email: "user@example.com", password: "123456"})
```

### OAUTH2

Oauth is performed on the client by redirecting the user. To get the redirection URL, call `GoTrue.url_for_provider/1`: 

```elixir
GoTrue.url_for_provider(:google)
GoTrue.url_for_provider(:github)
GoTrue.url_for_provider(:gitlab)
GoTrue.url_for_provider(:bitbucket)
GoTrue.url_for_provider(:facebook)
```

### Magic Link

Users can login without password, by requesting a magic link:

```elixir
GoTrue.send_magic_link("user@example.com")
```

That sends them an email with a link to login. The link will contain the `access_token` & `refresh_token`.

## Sign in

If you're using password logins, sign in a user by passing the `email` & `password` to `GoTrue.sign_in/1`, it returns a JWT

```elixir
GoTrue.sign_in(%{email: "user@example.com", password: "12345"})
```

## Refreshing JWT

Each JWT expires based on your GoTrue server's settings. To refresh it, pass the `refresh_token` to `GoTrue.refresh_access_token/1`

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
%{access_token: new_jwt} = GoTrue.refresh_access_token(refresh_token)
```

## Sign out

To revoke a JWT, call `GoTrue.sign_out/1`

```elixir
GoTrue.sign_out(jwt)
```

## Getting user info

The user's info can be accessed by calling `GoTrue.get_user/1` with their current JWT:

```elixir
GoTrue.get_user(jwt)
```

## Updating user info

Using a JWT, the user's data can be updated by calling `GoTrue.update_user/2`

```elixir
GoTrue.update_user(jwt, %{data: %{favorite_language: "elixir"}})
```

## Invitations

Users can be invited by passing their email address to `GoTrue.invite/1`, this sends them an email with a completion link.

```elixir
GoTrue.invite(%{email: "user@example.com"})
```

## Settings

To view the server's auth settings, call `GoTrue.settings()`

# License

MIT
