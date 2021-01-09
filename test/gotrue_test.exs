defmodule GoTrueTest do
  use ExUnit.Case
  doctest GoTrue

  test "greets the world" do
    assert GoTrue.hello() == :world
  end
end
