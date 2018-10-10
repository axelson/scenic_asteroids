defmodule Play.Component.Nav do
  use Scenic.Component

  alias Scenic.ViewPort
  alias Scenic.Graph

  import Scenic.Primitives, only: [{:text, 3}, {:rect, 3}]
  import Scenic.Components, only: [{:dropdown, 3}]
  import Scenic.Clock.Components

  # import IEx

  @height 60

  def height, do: @height

  # --------------------------------------------------------
  @impl Scenic.Component
  def verify(scene) when is_atom(scene), do: {:ok, scene}
  def verify({scene, _} = data) when is_atom(scene), do: {:ok, data}
  def verify(_), do: :invalid_data

  # ----------------------------------------------------------------------------
  @impl Scenic.Scene
  def init(current_scene, opts) do
    Process.register(self(), __MODULE__)

    styles = opts[:styles] || %{}

    # Get the viewport width
    {:ok, %ViewPort.Status{size: {width, _}}} =
      opts[:viewport]
      |> ViewPort.info()

    graph =
      Graph.build(styles: styles, font_size: 20)
      |> rect({width, @height}, fill: {48, 48, 48})
      |> text("Scene:", translate: {14, 35}, align: :right)
      |> dropdown(
        {[
           {"Asteroids", Play.Scene.Asteroids},
           {"Sensor", Play.Scene.Sensor},
           {"Primitives", Play.Scene.Primitives},
           {"Components", Play.Scene.Components},
           {"Transforms", Play.Scene.Transforms}
         ], current_scene},
        id: :nav,
        translate: {70, 15}
      )
      |> digital_clock(text_align: :right, translate: {width - 20, 35})
      |> Scenic.Components.button("Reload", id: :reload_app_btn, width: 100, translate: {240, 15})
      |> push_graph()

    {:ok, %{graph: graph, viewport: opts[:viewport], current_scene: current_scene}}
  end

  @impl Scenic.Scene
  def filter_event({:value_changed, :nav, scene}, _, %{viewport: vp} = state)
      when is_atom(scene) do
    ViewPort.set_root(vp, {scene, nil})
    {:stop, state}
  end

  def filter_event({:value_changed, :nav, scene}, _, %{viewport: vp} = state) do
    ViewPort.set_root(vp, scene)
    {:stop, state}
  end

  def filter_event({:click, :reload_app_btn}, _pid, %{graph: graph, current_scene: current_scene} = state) do
    reload_current_scene(current_scene)

    graph =
      graph
      |> Graph.modify(:reload_app_btn, &Scenic.Components.button(&1, "Reloaded", []))
      |> push_graph()

    {:stop, %{state | graph: graph}}
  end

  def handle_call(:reload_current_scene, _, state) do
    IO.puts "Reload current scene from call3!"
    %{current_scene: current_scene} = state
    reload_current_scene(current_scene)
    {:reply, nil, state}
  end

  defp reload_current_scene(current_scene) do
    current_scene
    |> Process.whereis()
    |> case do
         nil -> nil
         pid -> Process.exit(pid, :kill)
       end
  end
end
