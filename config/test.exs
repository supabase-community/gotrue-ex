import Config

config :tesla, adapter: Tesla.Mock

config :gotrue,
  base_url: "http://auth.example.com",
  api_key: "super-secret"
