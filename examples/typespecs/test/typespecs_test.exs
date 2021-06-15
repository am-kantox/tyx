defmodule TypespecsTest do
  use ExUnit.Case
  doctest Typespecs

  test "greets the world" do
    assert Typespecs.hello() == :world
  end
end
