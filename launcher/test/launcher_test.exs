defmodule LauncherTest do
  use ExUnit.Case
  doctest Launcher

  test "greets the world" do
    assert Launcher.hello() == :world
  end
end
