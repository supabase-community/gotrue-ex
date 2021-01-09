defmodule GoTrue do
  @moduledoc """
  Elixir wrapper for [GoTrue Authentication Service](https://github.com/supabase/gotrue).
  """

  use Tesla

  plug Tesla.Middleware.BaseUrl, Application.get_env(:gotrue, :base_url, "http://0.0.0.0:9999")
  plug Tesla.Middleware.Headers, [authorization: "Bearer #{Application.get_env(:gotrue, :access_token)}"]
  plug Tesla.Middleware.JSON

  @doc "Get environment settings for the GoTrue server"
  @spec settings() :: map
  def settings do
    {:ok, %{status: 200, body: json}} = get("/settings")

    json
  end

  @doc "Sign up a new user with email and password"
  @spec sign_up(%{
          required(:email) => String.t(),
          required(:password) => String.t(),
          data: map(),
          audience: String.t(),
          provider: String.t()
        }) :: map
  def sign_up(credentials) do
    payload =
      credentials
      |> Map.take([:email, :password, :data, :provider])
      |> Map.merge(%{aud: credentials[:audience]})

    case post("/signup", payload) do
      {:ok, %{status: 200, body: json}} ->
        {:ok,
         %{
           access_token: json["access_token"],
           expires_in: json["expires_in"],
           token_type: json["token_type"],
           refresh_token: json["refresh_token"],
           user: json["user"]
         }}

      {:ok, %{status: status, body: json}} ->
        {:error, %{code: status, message: json["msg"]}}
    end
  end
end
