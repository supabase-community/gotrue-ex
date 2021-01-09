import Config

config :tesla, adapter: Tesla.Mock

config :gotrue,
  base_url: "http://auth.example.com",
  access_token: "super-secret"
