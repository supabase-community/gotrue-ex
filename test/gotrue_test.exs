defmodule GoTrueTest do
  use ExUnit.Case

  import Tesla.Mock

  setup do
    mock(fn
      %{method: :get, url: "http://auth.example.com/settings"} ->
        json(%{"a_setting" => 1234})

      %{
        method: :post,
        url: "http://auth.example.com/invite",
        body: ~s|{"email":"existing@example.com"}|
      } ->
        json(%{"msg" => "already registered"}, status: 422)

      %{method: :post, url: "http://auth.example.com/invite"} ->
        json(%{"email" => "user@example.com"})
    end)

    :ok
  end

  test "settings/0" do
    assert GoTrue.settings() == %{"a_setting" => 1234}
  end

  describe "sign_up/1" do
    test "with invalid response" do
      mock(fn
        %{method: :post, url: "http://auth.example.com/signup"} ->
          json(%{"msg" => "invalid"}, status: 422)
      end)

      assert GoTrue.sign_up(%{email: "user@example.com", password: "oops"}) ==
               {:error, %{code: 422, message: "invalid"}}
    end

    test "with duplicate response" do
      mock(fn
        %{method: :post, url: "http://auth.example.com/signup"} ->
          json(%{"msg" => "already exists"}, status: 400)
      end)

      assert GoTrue.sign_up(%{email: "exists@example.com", password: "12345"}) ==
               {:error, %{code: 400, message: "already exists"}}
    end

    test "with valid params" do
      mock(fn
        %{
          method: :post,
          url: "http://auth.example.com/signup",
          body:
            ~s|{"aud":null,"data":{"favorite_language":"elixir"},"email":"user@example.com","password":"12345"}|
        } ->
          json(
            %{
              access_token: "1234",
              expires_in: 60,
              token_type: "bearer",
              refresh_token: "abcd",
              user: %{}
            },
            status: 200
          )
      end)

      assert GoTrue.sign_up(%{
               email: "user@example.com",
               password: "12345",
               data: %{favorite_language: "elixir"}
             }) ==
               {:ok,
                %{
                  access_token: "1234",
                  expires_in: 60,
                  refresh_token: "abcd",
                  token_type: "bearer",
                  user: %{}
                }}
    end

    test "with extra params" do
      mock(fn
        %{
          method: :post,
          url: "http://auth.example.com/signup",
          body:
            ~s|{"aud":"superheros","data":{"favorite_language":"elixir"},"email":"user@example.com","password":"12345","provider":"email"}|
        } ->
          json(
            %{
              access_token: "1234",
              expires_in: 60,
              token_type: "bearer",
              refresh_token: "abcd",
              user: %{}
            },
            status: 200
          )
      end)

      assert GoTrue.sign_up(%{
               email: "user@example.com",
               password: "12345",
               data: %{favorite_language: "elixir"},
               audience: "superheros",
               provider: "email"
             }) ==
               {:ok,
                %{
                  access_token: "1234",
                  expires_in: 60,
                  refresh_token: "abcd",
                  token_type: "bearer",
                  user: %{}
                }}
    end
  end

  describe "invite/1" do
    test "with invalid params" do
      assert GoTrue.invite(%{email: "existing@example.com"}) ==
               {:error, %{code: 422, message: "already registered"}}
    end

    test "with valid params" do
      assert GoTrue.invite(%{
               email: "user@example.com",
               data: %{favorite_language: "elixir"}
             }) == {:ok, %{"email" => "user@example.com"}}
    end
  end
end
