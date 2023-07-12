defmodule GoTrue do
  @moduledoc """
  Elixir wrapper for the [GoTrue authentication service](https://github.com/supabase/gotrue).
  """

  import Tesla, only: [get: 2, post: 3, put: 3]

  def client() do
    base_url = get_base_url()
    api_key = Application.get_env(:gotrue, :api_key)
    client(base_url, api_key)
  end

  def client(base_url, api_key) do
    middlewares = [
      {Tesla.Middleware.BaseUrl, base_url},
      Tesla.Middleware.JSON,
      {Tesla.Middleware.Headers, [{"apikey", api_key}, {"authorization", "Bearer #{api_key}"}]}
    ]

    Tesla.client(middlewares)
  end

  @doc "Get environment settings for the server"
  @spec settings() :: map
  def settings do
    client()
    |> settings()
  end

  def settings(client) do
    client
    |> get("/settings")
    |> handle_response(200, fn %{body: json} -> json end)
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
    client()
    |> sign_up(credentials)
  end

  def sign_up(client, credentials) do
    payload =
      credentials
      |> Map.take([:email, :password, :data, :provider])
      |> Map.merge(%{aud: credentials[:audience]})

    client
    |> post("/signup", payload)
    |> handle_response(200, fn %{body: json} -> {:ok, json} end)
  end

  @doc "Send a password recovery email"
  @spec recover(String.t()) :: :ok | {:error, map}
  def recover(email) do
    client()
    |> recover(email)
  end

  def recover(client, email) do
    client
    |> post("/recover", %{email: email})
    |> handle_response()
  end

  @doc "Invite a new user to join"
  @spec invite(%{
          required(:email) => String.t(),
          data: map()
        }) :: map
  def invite(invitation) do
    client()
    |> invite(invitation)
  end

  def invite(client, invitation) do
    client
    |> post("/invite", invitation)
    |> handle_response(200, &user_handler/1)
  end

  @doc "Send a magic link (passwordless login)"
  @spec send_magic_link(String.t()) :: :ok | {:error, map}
  def send_magic_link(email) do
    client()
    |> send_magic_link(email)
  end

  def send_magic_link(client, email) do
    client
    |> post("/magiclink", %{email: email})
    |> handle_response()
  end

  @doc "Generate a URL for authorizing with an OAUTH2 provider"
  @spec url_for_provider(String.t()) :: String.t()
  def url_for_provider(provider) do
    get_base_url()
    |> url_for_provider(provider)
  end

  def url_for_provider(base_url, provider) do
    base_url
    |> URI.merge("authorize?provider=#{provider}")
    |> URI.to_string()
  end

  @doc "Refresh access token using a valid refresh token"
  @spec refresh_access_token(String.t()) :: {:ok, map()} | {:error, map}
  def refresh_access_token(refresh_token) do
    client()
    |> refresh_access_token(refresh_token)
  end

  def refresh_access_token(client, refresh_token) do
    grant_token(client, :refresh_token, %{refresh_token: refresh_token})
  end

  @doc "Sign in with email and password"
  @spec sign_in(%{required(:email) => String.t(), required(:password) => String.t()}) ::
          {:ok, map()} | {:error, map}
  def sign_in(credentials) do
    client()
    |> sign_in(credentials)
  end

  def sign_in(client, credentials) do
    grant_token(client, :password, credentials)
  end

  defp grant_token(client, type, payload) do
    client
    |> post("/token?grant_type=#{type}", payload)
    |> handle_response(200, fn %{body: json} -> {:ok, json} end)
  end

  @doc "Sign out user using a valid JWT"
  @spec sign_out(String.t()) :: :ok | {:error, map}
  def sign_out(jwt) do
    client()
    |> sign_out(jwt)
  end

  def sign_out(client, jwt) do
    client
    |> update_header({:authorization, jwt})
    |> post("/logout", %{})
    |> handle_response(204)
  end

  @doc "Get user info using a valid JWT"
  @spec get_user(String.t()) :: {:ok, map} | {:error, map}
  def get_user(jwt) do
    client()
    |> get_user(jwt)
  end

  def get_user(client, jwt) do
    client
    |> update_header({:authorization, jwt})
    |> get("/user")
    |> handle_response(200, &user_handler/1)
  end

  @doc "Update user info using a valid JWT"
  @spec update_user(String.t(), map()) :: {:ok, map} | {:error, map}
  def update_user(jwt, info) do
    client()
    |> update_user(jwt, info)
  end

  def update_user(client, jwt, info) do
    client
    |> update_header({:authorization, jwt})
    |> put("/user", info)
    |> handle_response(200, &user_handler/1)
  end

  defp parse_user(user) do
    user
  end

  defp format_error(%{status: status, body: json}) do
    %{code: status, message: json["msg"]}
  end

  defp default_handler(_response) do
    :ok
  end

  defp user_handler(%{body: json}) do
    {:ok, parse_user(json)}
  end

  defp handle_response({tag, response}, success \\ 200, fun \\ &default_handler/1) do
    case {tag, response} do
      {:ok, %{status: ^success}} ->
        fun.(response)

      {:ok, response} ->
        {:error, format_error(response)}
    end
  end

  defp get_base_url() do
    Application.get_env(:gotrue, :base_url, "http://0.0.0.0:9999")
  end

  def update_header(client, {:authorization, value}) do
    case client
         |> Tesla.Client.middleware()
         |> List.keytake(Tesla.Middleware.Headers, 0) do
      {{Tesla.Middleware.Headers, headers}, middleware} ->
        Tesla.client([
          {Tesla.Middleware.Headers,
           List.keystore(headers, "authorization", 0, {"authorization", "Bearer #{value}"})}
          | middleware
        ])

      _ ->
        middleware = Tesla.Client.middleware(client)

        Tesla.client([
          {Tesla.Middleware.Headers, {"authorization", "Bearer #{value}"}} | middleware
        ])
    end
  end

  def update_header(client, _), do: client
end
