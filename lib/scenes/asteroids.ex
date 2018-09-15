defmodule Play.Scene.Asteroids do
  @moduledoc """
  Asteroids animation/game
  """

  use Scenic.Scene
  import Scenic.Primitives

  alias Scenic.Graph
  alias Play.Component.Nav

  # Steps
  # [x] Draw a circle to represent an asteroid
  # [x] Draw the circle empty
  # [x] Animate the circle
  # [ ] Make multiple circles
  # [ ] Draw the player

  @initial_graph Graph.build()
                 |> circle(30, id: :asteroid1, stroke: {3, :white}, t: {110, 290})
                 |> Nav.add_to_graph(__MODULE__)

  @impl true
  def init(_, opts) do
    Process.register(self(), __MODULE__)
    push_graph(@initial_graph)
    IO.puts "init4"
    schedule_animate()

    {:ok, %{graph: @initial_graph, t: 0}}
  end

  @impl true
  def handle_info(:animate, state) do
    %{graph: graph, t: t} = state
    schedule_animate()

    graph =
      graph
      |> Graph.modify(:asteroid1, &circle(&1, 30, t: {110, 100 + t * 10}))
      |> push_graph()

    {:noreply, %{state | t: t + 1, graph: graph}}
  end

  defp schedule_animate(), do: Process.send_after(self(), :animate, 100)
end
