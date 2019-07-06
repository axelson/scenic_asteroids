defmodule Launcher do
  @moduledoc """
  Documentation for Launcher.
  """

  alias Scenic.ViewPort

  @doc """
  Switches to the main launcher screen
  """
  def switch_to_launcher(viewport) do
    IO.puts "Switching to launcher!"
    ViewPort.set_root(viewport, {Launcher.Scene.Home, nil})
  end
end
