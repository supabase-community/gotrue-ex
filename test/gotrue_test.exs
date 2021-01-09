defmodule GoTrueTest do
  use ExUnit.Case

  import Tesla.Mock

  setup do
    mock(fn
      %{method: :get, url: "http://auth.example.com/settings"} ->
        json(%{"a_setting" => 1234})
    end)

    :ok
  end

  test "settings/0" do
    assert GoTrue.settings() == %{"a_setting" => 1234}
  end
end
