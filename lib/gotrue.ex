defmodule GoTrue do
  @moduledoc """
  Elixir wrapper for [GoTrue Authentication Service](https://github.com/supabase/gotrue).
  """

  use Tesla

  plug Tesla.Middleware.BaseUrl, Application.get_env(:gotrue, :base_url, "http://0.0.0.0:9999")

  plug Tesla.Middleware.Headers,
    authorization: "Bearer #{Application.get_env(:gotrue, :access_token)}"

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
           user: parse_user(json["user"])
         }}

      {:ok, response} ->
        {:error, format_error(response)}
    end
  end

  @doc "Invite a new user to join"
  @spec invite(%{
          required(:email) => String.t(),
          data: map()
        }) :: map
  def invite(invitation) do
    case post("/invite", invitation) do
      {:ok, %{status: 200, body: json}} ->
        {:ok, parse_user(json)}

      {:ok, response} ->
        {:error, format_error(response)}
    end
  end

  @doc "Send a magic link (passwordless login)"
  @spec send_magic_link(String.t()) :: :ok | {:error, map}
  def send_magic_link(email) do
    case post("/magiclink", %{email: email}) do
      {:ok, %{status: 200}} ->
        :ok

      {:ok, response} ->
        {:error, format_error(response)}
    end
  end

  defp parse_user(user) do
    user
  end

  defp format_error(%{status: status, body: json}) do
    %{code: status, message: json["msg"]}
  end
end
