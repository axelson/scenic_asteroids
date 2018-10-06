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
  # [x] Live reloading!
  # [x] Press `r` to reload!
  # [x] Make multiple circles
  # [ ] Draw the player

  # Questions: Should there be a process per asteroid?

  # Note: Asteroids start off the screen
  @initial_graph Graph.build()
                 |> circle(30, id: :asteroid1, stroke: {3, :white}, t: {0, -100})
                 |> circle(30, id: :asteroid2, stroke: {3, :white}, t: {0, -100})
                 |> Nav.add_to_graph(__MODULE__)

  @impl Scenic.Scene
  def init(_, _opts) do
    Process.register(self(), __MODULE__)
    push_graph(@initial_graph)
    schedule_animate()

    {:ok, %{graph: @initial_graph, t: 0, x: 110}}
  end

  def handle_info(:animate, state) do
    %{graph: graph, t: t, x: x} = state
    schedule_animate()

    # x = x - 1 / 4
    x = x + :rand.uniform() * 2

    graph =
      graph
      |> Graph.modify(:asteroid1, &circle(&1, 30, t: {x, 100 + t * 1}))
      |> Graph.modify(:asteroid2, &circle(&1, 30, t: {x, 200 + t * 1}))
      |> push_graph()

    {:noreply, %{state | t: t + 1, x: x, graph: graph}}
  end

  @impl Scenic.Scene
  def filter_event(event, sec, state) do
    IO.inspect(event, label: "event")
    IO.inspect(sec, label: "sec")

    {:continue, event, state}
  end

  @impl Scenic.Scene
  def handle_input({:key, {"R", :press, _}}, _viewport_context, state) do
    GenServer.call(Play.Component.Nav, :reload_current_scene)

    {:noreply, state}
  end

  def handle_input(input, _, state) do
    IO.inspect(input, label: "#{__MODULE__} ignoring input")
    {:noreply, state}
  end

  # def handle_input(_, _, state), do: {:noreply, state}

  defp schedule_animate(), do: Process.send_after(self(), :animate, 10)
end
