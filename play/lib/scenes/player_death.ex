defmodule Play.Scene.PlayerDeath do
  @moduledoc """
  Render the player's death
  """

  use Scenic.Scene
  import Scenic.Primitives
  alias Scenic.Graph

  @initial_graph Graph.build()
                 |> Launcher.HiddenHomeButton.add_to_graph([])

  defmodule State do
    @moduledoc false
    defstruct [:size, :graph, :time, :player_scores, :viewport]

    @type t :: %__MODULE__{}
  end

  @impl Scenic.Scene
  def init(scene, {{x, y}, player_scores}, _scenic_opts) do
    size = 3

    graph =
      @initial_graph
      |> circle(size, t: {x, y}, id: :circle, stroke: {3, :white}, fill: :white)

    state = %State{
      graph: graph,
      size: size,
      time: 0,
      viewport: scene.viewport,
      player_scores: player_scores
    }

    Process.send_after(self(), :animate, 10)

    scene =
      scene
      |> assign(:state, state)
      |> push_graph(graph(state))

    {:ok, scene}
  end

  @impl GenServer
  def handle_info(:animate, %{assigns: %{state: %{time: t}}} = scene) when t >= 150 do
    state = scene.assigns.state
    %{player_scores: player_scores} = state
    Scenic.ViewPort.set_root(scene.viewport, Play.Scene.GameOver, player_scores)
    {:noreply, scene}
  end

  def handle_info(:animate, scene) do
    state = scene.assigns.state
    %{graph: graph, size: size} = state

    graph =
      graph
      |> Graph.modify(:circle, &circle(&1, size))

    Process.send_after(self(), :animate, 10)
    state = %{state | graph: graph, size: size + 1, time: state.time + 1}

    scene =
      scene
      |> assign(:state, state)
      |> push_graph(graph(state))

    {:noreply, scene}
  end

  defp graph(%State{graph: graph}), do: graph
end
