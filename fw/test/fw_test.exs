defmodule FwTest do
  use ExUnit.Case
  doctest Fw

  test "greets the world" do
    assert Fw.hello() == :world
  end
end
