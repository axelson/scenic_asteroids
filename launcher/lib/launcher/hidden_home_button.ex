defmodule Launcher.HiddenHomeButton do
  @moduledoc """
  A transparent button that will switch back to the main launcher screen. Should
  be rendered last so that it is on the top and can be clicked/tapped.
  """
  use Scenic.Component, has_children: true

  alias Scenic.Graph
  alias Scenic.ViewPort

  @width 30
  @height 30

  defmodule State do
    defstruct [:viewport]
  end

  @impl Scenic.Component
  def verify(data), do: {:ok, data}

  @impl Scenic.Scene
  def init(_, scenic_opts) do
    viewport = scenic_opts[:viewport]
    {:ok, %{size: {screen_width, screen_height}}} = ViewPort.info(viewport)

    graph =
      Graph.build()
      |> Scenic.Primitives.rect({@width, @height}, fill: :clear, t: {screen_width - @width, 0})

    {:ok, %State{viewport: viewport}, push: graph}
  end

  @impl Scenic.Scene
  def handle_input({:cursor_button, {_, :press, _, _}}, _context, state) do
    Launcher.switch_to_launcher(state.viewport)
    {:noreply, state}
  end

  def handle_input(_input, _context, state) do
    {:noreply, state}
  end

  defp sleep_screen do
    backlight = Application.get_env(:launcher, :backlight_module)
    if backlight do
      backlight.brightness(0)
    end
  end
end
