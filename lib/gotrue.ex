defmodule GoTrue do
  @moduledoc """
  Elixir wrapper for [GoTrue Authentication Service](https://github.com/supabase/gotrue).
  """

  use Tesla

  plug Tesla.Middleware.BaseUrl, Application.get_env(:gotrue, :base_url, "http://0.0.0.0:9999")
  plug Tesla.Middleware.JSON

  @doc "Get environment settings for the GoTrue server"
  def settings do
    {:ok, %{status: 200, body: json}} = get("/settings")

    json
  end
end
