defmodule Play.Scene.Asteroids do
  @moduledoc """
  Asteroids animation/game
  """

  use Scenic.Scene
  import Scenic.Primitives

  alias Scenic.Graph
  alias Play.Component.Nav

  defmodule State do
    defstruct [:t, :x, :graph, :last_run_time, :player_coords, :key_states, :bullets]
  end

  # Steps
  # [x] Draw a circle to represent an asteroid
  # [x] Draw the circle empty
  # [x] Animate the circle
  # [x] Live reloading!
  # [x] Press `r` to reload!
  # [x] Make multiple circles
  # [x] Draw the player
  # [x] Constrain the player to the screen
  # [x] Create bullets
  # [x] Animate bullets
  # [ ] Limit # bullets
  # [ ] Remove bullets after they are off the screen
  # [ ] Track state of spacebar so we can repeat fire and move
  # [ ] Collision detection!

  # Question: Should there be a process per asteroid?
  # Answer: No!

  @movement_keys ["W", "A", "S", "D"]

  @player_dimensions {{0, 0}, {30, 0}, {15, 30}}
  # Note: Asteroids start off the screen
  @initial_graph Graph.build()
                 |> circle(30, id: :asteroid1, stroke: {3, :white}, t: {0, -100})
                 |> circle(30, id: :asteroid2, stroke: {3, :white}, t: {0, -100})
                 |> triangle(@player_dimensions, id: :player, stroke: {1, :white})
                 |> Nav.add_to_graph(__MODULE__)

  @impl Scenic.Scene
  def init(_, _opts) do
    Process.register(self(), __MODULE__)
    push_graph(@initial_graph)
    schedule_animations()

    initial_state = %State{
      graph: @initial_graph,
      t: 0,
      x: 110,
      player_coords: initial_player_coordinates(),
      key_states: %{},
      bullets: []
    }

    {:ok, initial_state}
  end

  def initial_player_coordinates do
    width = Play.Utils.screen_width() / 2
    height = Play.Utils.screen_height() / 2
    {width, height}
  end

  def handle_info({:animate, expected_run_time}, state) do
    diff = time_diff(state, expected_run_time)
    state = update_player_coords_based_on_keys(state)
    %{graph: graph, t: t, x: x, player_coords: player_coords, bullets: bullets} = state

    bullets = tick_bullets(bullets)

    speed = 100

    dist =
      case diff do
        0 -> 0
        diff -> speed / 1000 * diff
      end

    x = x + dist

    graph =
      graph
      |> Graph.modify(:asteroid1, &circle(&1, 30, t: {x, 100}))
      |> Graph.modify(:asteroid2, &circle(&1, 30, t: {x, 200}))
      |> Graph.modify(:player, &triangle(&1, @player_dimensions, t: player_coords))
      |> animate_bullets(bullets)
      |> push_graph()

    new_state = %{state | t: t + 1, x: x, graph: graph, last_run_time: expected_run_time, bullets: bullets}
    {:noreply, new_state}
  end

  defp tick_bullets(bullets) do
    bullets
    |> Enum.reduce([], fn bullet, bullets ->
      bullet = Play.Bullet.tick(bullet)
      [bullet | bullets]
    end)
  end

  defp animate_bullets(graph, bullets) do
    bullets
    |> Enum.reduce(graph, fn bullet, graph ->
      graph
      |> Graph.modify(bullet.id, build_render_bullet(bullet))
    end)
  end

  defp time_diff(state, expected_run_time) do
    last_run_time = Map.get(state, :last_run_time) || expected_run_time
    DateTime.diff(expected_run_time, last_run_time, :millisecond)
  end

  @impl Scenic.Scene
  def filter_event(event, sec, state) do
    IO.inspect(event, label: "event")
    IO.inspect(sec, label: "sec")

    {:continue, event, state}
  end

  @impl Scenic.Scene
  def handle_input(input, viewport_context, state) do
    # IO.inspect(input, label: "#{__MODULE__} received input")
    do_handle_input(input, viewport_context, state)
  end

  def do_handle_input({:key, {"R", :press, _}}, _viewport_context, state) do
    GenServer.call(Play.Component.Nav, :reload_current_scene)

    {:noreply, state}
  end

  def do_handle_input({:key, {key, action, _}}, _viewport_context, state)
      when key in @movement_keys and action in [:press, :repeat, :release] do
    %{player_coords: {width, height}} = state
    state = record_key_state(state, key, action)

    {:noreply, state}
  end

  def do_handle_input({:key, {" ", action, _}}, _viewport_context, state)
      when action in [:press, :repeat] do
    state = shoot(state)
    {:noreply, state}
  end

  def do_handle_input(input, _, state) do
    # IO.inspect(input, label: "#{__MODULE__} ignoring input")
    {:noreply, state}
  end

  defp record_key_state(%State{} = state, key, action) do
    key_states = state.key_states

    key_states =
      case action do
        :press -> Map.put(key_states, key, true)
        :release -> Map.delete(key_states, key)
        _ -> key_states
      end

    %{state | key_states: key_states}
  end

  @spec shoot(%State{}) :: %State{}
  defp shoot(state) do
    IO.puts "pew pew"
    %{bullets: bullets, graph: graph, player_coords: player_coords} = state

    bullet = Play.Bullet.new(player_coords)
    graph = render_bullet(graph, bullet)

    %{state | bullets: [bullet | bullets], graph: graph}
  end

  defp build_render_bullet(bullet) do
    fn graph -> render_bullet(graph, bullet) end
  end

  defp render_bullet(graph, bullet) do
    circle(graph, 5, id: bullet.id, t: bullet.t, stroke: {1, :white})
  end

  defp schedule_animations() do
    pid = self()
    # Process.send_after(self(), :animate, 2)
    func = fn expected_run_time ->
      Process.send(pid, {:animate, expected_run_time}, [])
    end

    SchedEx.run_in(func, 1, repeat: true, time_scale: Play.GameTimer)
  end

  defp key_to_direction("W"), do: :up
  defp key_to_direction("A"), do: :left
  defp key_to_direction("S"), do: :down
  defp key_to_direction("D"), do: :right

  defp update_player_coords(%State{} = state, direction) do
    %{player_coords: {width, height}} = state
    dist = 5

    updated_coords =
      case direction do
        :up -> {width, height - dist}
        :left -> {width - dist, height}
        :down -> {width, height + dist}
        :right -> {width + dist, height}
      end
      |> constrain_player_to_screen()

    %{state | player_coords: updated_coords}
  end

  defp constrain_player_to_screen({width, height}) do
    {_, {player_width, _}, {_, player_height}} = @player_dimensions

    min_width = 0
    max_width = Play.Utils.screen_width() - player_width

    min_height = Nav.height()
    max_height = Play.Utils.screen_height() - player_height

    {constrain(width, min_width, max_width), constrain(height, min_height, max_height)}
  end

  defp constrain(value, min, max) do
    value
    |> min(max)
    |> max(min)
  end

  defp update_player_coords_based_on_keys(%State{} = state) do
    %{player_coords: {width, height}, key_states: key_states} = state

    key_states
    |> Enum.reduce(state, fn {key, _key_state}, state ->
      direction = key_to_direction(key)
      update_player_coords(state, direction)
    end)
  end
end
