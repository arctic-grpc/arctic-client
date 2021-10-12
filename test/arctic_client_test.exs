defmodule ArcticClientTest do
  use ExUnit.Case
  doctest ArcticClient

  test "greets the world" do
    assert ArcticClient.hello() == :world
  end
end
