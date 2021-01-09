defmodule GoTrue do
  @moduledoc """
  Elixir wrapper for [GoTrue Authentication Service](https://github.com/supabase/gotrue).
  """

  use Tesla

  @base_url Application.get_env(:gotrue, :base_url, "http://0.0.0.0:9999")
  @access_token Application.get_env(:gotrue, :access_token)

  @doc "Get environment settings for the GoTrue server"
  @spec settings() :: map
  def settings do
    {:ok, %{status: 200, body: json}} = client() |> get("/settings")

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

    case client() |> post("/signup", payload) do
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

  @doc "Send a password recovery email"
  @spec recover(String.t()) :: :ok | {:error, map}
  def recover(email) do
    case client() |> post("/recover", %{email: email}) do
      {:ok, %{status: 200}} ->
        :ok

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
    case client() |> post("/invite", invitation) do
      {:ok, %{status: 200, body: json}} ->
        {:ok, parse_user(json)}

      {:ok, response} ->
        {:error, format_error(response)}
    end
  end

  @doc "Send a magic link (passwordless login)"
  @spec send_magic_link(String.t()) :: :ok | {:error, map}
  def send_magic_link(email) do
    case client() |> post("/magiclink", %{email: email}) do
      {:ok, %{status: 200}} ->
        :ok

      {:ok, response} ->
        {:error, format_error(response)}
    end
  end

  @doc "Generate a URL for authorizing with an OAUTH2 provider"
  @spec url_for_provider(String.t()) :: String.t()
  def url_for_provider(provider) do
    @base_url
    |> URI.merge("authorize?provider=#{provider}")
    |> URI.to_string()
  end

  @doc "Refresh access token using a valid refresh token"
  @spec refresh_access_token(String.t()) :: {:ok, map()} | {:error, map}
  def refresh_access_token(refresh_token) do
    case client() |> post("/token", %{refresh_token: refresh_token}) do
      {:ok, %{status: 204, body: json}} ->
        {:ok, json}

      {:ok, response} ->
        {:error, format_error(response)}
    end
  end

  @doc "Sign out user using a valid JWT"
  @spec sign_out(String.t()) :: :ok | {:error, map}
  def sign_out(jwt) do
    case client(jwt) |> post("/logout", %{}) do
      {:ok, %{status: 204}} ->
        :ok

      {:ok, response} ->
        {:error, format_error(response)}
    end
  end

  @doc "Get user info using a valid JWT"
  @spec get_user(String.t()) :: {:ok, map} | {:error, map}
  def get_user(jwt) do
    case client(jwt) |> get("/user") do
      {:ok, %{status: 200, body: json}} ->
        {:ok, parse_user(json)}

      {:ok, response} ->
        {:error, format_error(response)}
    end
  end

  @doc "Update user info using a valid JWT"
  @spec update_user(String.t(), map()) :: {:ok, map} | {:error, map}
  def update_user(jwt, info) do
    case client(jwt) |> put("/user", info) do
      {:ok, %{status: 200, body: json}} ->
        {:ok, parse_user(json)}

      {:ok, response} ->
        {:error, format_error(response)}
    end
  end

  defp client(access_token \\ @access_token) do
    middleware = [
      {Tesla.Middleware.BaseUrl, @base_url},
      Tesla.Middleware.JSON,
      {Tesla.Middleware.Headers, authorization: "Bearer #{access_token}"}
    ]

    Tesla.client(middleware)
  end

  defp parse_user(user) do
    user
  end

  defp format_error(%{status: status, body: json}) do
    %{code: status, message: json["msg"]}
  end
end
