defmodule GoTrue.ClientTest do
  use GoTrue.ConnCase, async: true

  describe "sign_up/1" do
    test "with invalid response", %{conn: conn} do
      credetials =
        mock_credentials()
        |> Map.update!(:password, &String.slice(&1, 0..4))

      assert sign_up(conn, credetials) ==
               {:error, %{code: 422, message: "Password should be at least 6 characters"}}
    end

    test "with duplicate response", %{conn: conn} do
      credetials = mock_credentials()
      sign_up(conn, credetials)

      assert sign_up(conn, Map.update!(credetials, :password, &(&1 <> "foo"))) ==
               {:error, %{code: 400, message: "User already registered"}}
    end

    test "with valid params", %{conn: conn} do
      credentials = Map.put(mock_credentials(), :data, %{favorite_language: "elixir"})

      {:ok,
       %{
         "access_token" => access_token,
         "refresh_token" => refresh_token,
         "user" => %{
           "email" => email
         }
       }} = sign_up(conn, credentials)

      assert email == credentials[:email]
      assert access_token != ""
      assert refresh_token != ""
    end

    test "with extra params", %{conn: conn} do
      credentials =
        mock_credentials()
        |> Map.put(:audience, "superheros")
        |> Map.put(:provider, "email")
        |> Map.put(:data, %{favorite_language: "elixir"})

      {:ok,
       %{
         "access_token" => access_token,
         "refresh_token" => refresh_token,
         "user" => %{
           "email" => email,
           "user_metadata" => %{"favorite_language" => favorite_language}
         }
       }} = sign_up(conn, credentials)

      assert email == credentials[:email]
      assert favorite_language == credentials[:data][:favorite_language]
      assert access_token != ""
      assert refresh_token != ""
    end
  end

  describe "recover/1" do
    test "valid params", %{conn: conn} do
      credentials = mock_credentials()
      sign_up(conn, credentials)
      assert recover(conn, credentials[:email]) == :ok
    end

    test "invalid params", %{conn: conn} do
      assert recover(conn, "") ==
               {:error, %{message: "Password recovery requires an email", code: 422}}
    end
  end

  describe "send_magic_link/1" do
    test "valid params", %{conn: conn} do
      credentials = mock_credentials()
      sign_up(conn, credentials)
      assert send_magic_link(conn, credentials[:email]) == :ok
    end

    test "invalid params", %{conn: conn} do
      assert send_magic_link(conn, "") ==
               {:error, %{message: "Password recovery requires an email", code: 422}}
    end
  end

  describe "sign_in/1" do
    setup %{conn: conn} do
      credentials = mock_credentials()
      sign_up(conn, credentials)
      %{credentials: credentials}
    end

    test "with invalid params", %{conn: conn, credentials: credentials} do
      assert sign_in(conn, Map.update!(credentials, :password, &(&1 <> "foo"))) ==
               {:error, %{code: 400, message: nil}}
    end

    test "with valid params", %{conn: conn, credentials: credentials} do
      {:ok,
       %{
         "access_token" => access_token,
         "refresh_token" => refresh_token,
         "user" => %{
           "email" => email
         }
       }} = sign_in(conn, credentials)

      assert email == credentials[:email]
      assert access_token != ""
      assert refresh_token != ""
    end
  end

  describe "refresh_access_token/1" do
    setup %{conn: conn} do
      {:ok, session} = sign_up(conn, mock_credentials())
      %{session: session}
    end

    test "with invalid params", %{conn: conn} do
      assert refresh_access_token(conn, "refresh-token") ==
               {:error, %{code: 400, message: nil}}
    end

    test "with valid params", %{conn: conn, session: %{"refresh_token" => refresh_token}} do
      {:ok, %{"access_token" => access_token}} = refresh_access_token(conn, refresh_token)
      assert access_token != ""
    end
  end

  describe "sign_out/1" do
    setup %{conn: conn} do
      {:ok, session} = sign_up(conn, mock_credentials())
      %{session: session}
    end

    test "with invalid params", %{conn: conn} do
      assert sign_out(conn, "jwt-access-token") ==
               {:error,
                %{
                  code: 401,
                  message: "Invalid token: token contains an invalid number of segments"
                }}
    end

    test "with valid params", %{conn: conn, session: %{"access_token" => access_token}} do
      assert sign_out(conn, access_token) == :ok
    end
  end

  describe "invite/1" do
    setup %{conn: conn} do
      invitation = mock_credentials()
      sign_up(conn, invitation)
      %{invitation: Map.drop(invitation, [:password])}
    end

    test "with invalid params", %{conn: conn, invitation: invitation} do
      assert invite(conn, invitation) ==
               {:error,
                %{
                  code: 422,
                  message: "A user with this email address has already been registered"
                }}
    end

    test "with valid params", %{conn: conn} do
      invitation =
        mock_credentials()
        |> Map.drop([:password])
        |> Map.put(:favorite_language, "elixir")

      {:ok, %{"email" => email}} = invite(conn, invitation)
      assert email == invitation[:email]
    end
  end

  test "url_for_provider/1" do
    assert url_for_provider("http://localhost:9999", "google") ==
             "http://localhost:9999/authorize?provider=google"
  end

  describe "get_user/1" do
    setup %{conn: conn} do
      {:ok, session} = sign_up(conn, mock_credentials())
      %{session: session}
    end

    test "with invalid params", %{conn: conn} do
      assert get_user(conn, "jwt-access-token") ==
               {:error,
                %{
                  code: 401,
                  message: "Invalid token: token contains an invalid number of segments"
                }}
    end

    test "with valid params", %{
      conn: conn,
      session: %{"access_token" => access_token, "user" => %{"email" => email}}
    } do
      {:ok, %{"email" => current_email}} = get_user(conn, access_token)
      assert current_email == email
    end
  end

  describe "update_user/1" do
    setup %{conn: conn} do
      {:ok, session} = sign_up(conn, mock_credentials())
      %{session: session}
    end

    test "with invalid params", %{conn: conn} do
      assert update_user(conn, "jwt-access-token", %{data: %{name: "Josh"}}) ==
               {:error,
                %{
                  code: 401,
                  message: "Invalid token: token contains an invalid number of segments"
                }}
    end

    test "with valid params", %{
      conn: conn,
      session: %{"access_token" => access_token, "user" => %{"email" => email}}
    } do
      {:ok, %{"email" => current_email, "user_metadata" => %{"name" => name}}} =
        update_user(conn, access_token, %{data: %{name: "Josh"}})

      assert current_email == email
      assert name == "Josh"
    end
  end
end
