defmodule Play.Scene.Asteroids do
  @moduledoc """
  Asteroids animation/game
  """

  use Scenic.Scene
  import Scenic.Primitives

  alias Scenic.Graph
  alias Play.Asteroid
  alias Play.Bullet
  alias Play.CollisionBox

  @type game_time :: integer
  @type coords :: {width :: integer, height :: integer}

  defmodule State do
    @moduledoc false
    defstruct [
      :t,
      :graph,
      :player_coords,
      :key_states,
      :bullets,
      :asteroids,
      :last_shot
    ]

    @type t :: %__MODULE__{
            t: Play.Scene.Asteroids.game_time(),
            # graph: Scenic.Graph.t(),
            graph: %Graph{},
            player_coords: Play.Scene.Asteroids.coords(),
            key_states: %{required(String.t()) => true},
            bullets: list(Play.Bullet.t()),
            asteroids: list(Play.Asteroid.t()),
            last_shot: Play.Scene.Asteroids.game_time()
          }
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
  # [x] Loop the asteroids
  # [x] Remove bullets after they are off the screen
  # [x] Limit # bullets
  # [x] Track state of spacebar so we can repeat fire and move
  # [x] Basic Collision detection!
  # [x] Asteroid, bullet collision
  # [x] Shoot the asteroids
  # [ ] Create protocols
  # [ ] Asteroid move in vectors
  # [ ] Asteroid randomization
  # [ ] Asteroid spawning
  # [ ] Asteroid demolition into pieces

  # Question: Should there be a process per asteroid?
  # Answer: No!

  @movement_keys ["W", "A", "S", "D"]
  @firing_keys [" "]
  @keys_to_track @movement_keys ++ @firing_keys
  @max_bullets 5

  @player_dimensions {{0, 0}, {30, 0}, {15, 30}}
  @initial_graph Graph.build()
                 |> triangle(@player_dimensions, id: :player, stroke: {1, :white})

  @impl Scenic.Scene
  def init(_, _opts) do
    Process.register(self(), __MODULE__)
    push_graph(@initial_graph)
    schedule_animations()

    initial_state = %State{
      graph: @initial_graph,
      t: 0,
      player_coords: initial_player_coordinates(),
      key_states: %{},
      bullets: [],
      # Note: Asteroids start off the screen
      asteroids: [
        Play.Asteroid.new({-100, 31}, 30),
        Play.Asteroid.new({-100, 200}, 27),
        Play.Asteroid.new({-100, 300}, 12)
      ],
      last_shot: :never
    }

    initial_state = render_initial_graph(initial_state)

    {:ok, initial_state}
  end

  @spec render_initial_graph(%State{}) :: %State{}
  defp render_initial_graph(state) do
    %{graph: graph, asteroids: asteroids} = state

    graph =
      asteroids
      |> Enum.reduce(graph, fn asteroid, graph ->
        graph
        |> circle(asteroid.size, id: asteroid.id, stroke: {3, asteroid.color}, t: asteroid.t)
      end)

    %{state | graph: graph}
  end

  def handle_info({:animate, expected_run_time}, state) do
    state =
      state
      |> update_state_based_on_keys()
      # Tick updates our internal representation of state
      |> tick_time()
      |> tick_asteroids()
      |> tick_bullets()
      |> check_collisions()
      # Update the rendering of each element in the graph
      |> animate_player()
      |> animate_asteroids()
      |> animate_bullets()
      |> animate_collision_boxes()
      |> remove_dead_bullets()
      |> remove_dead_asteroids()

    %{graph: graph} = state
    push_graph(graph)

    # if rem(t, 100) == 0 do
    #   IO.inspect(graph, label: "graph")
    # end

    {:noreply, state}
  end

  defp tick_time(%State{t: t} = state), do: %{state | t: t + 1}

  defp animate_player(%State{graph: graph, player_coords: player_coords} = state) do
    graph = Graph.modify(graph, :player, &triangle(&1, @player_dimensions, t: player_coords))
    %{state | graph: graph}
  end

  defp animate_asteroids(%State{graph: graph, asteroids: asteroids} = state) do
    graph =
      asteroids
      |> Enum.reduce(graph, fn
        {:delete, id}, graph ->
          IO.puts("Deleting asteroid")
          Graph.delete(graph, id)

        asteroid, graph ->
          graph
          |> Graph.modify(asteroid.id, &render_asteroid(&1, asteroid))
      end)

    %{state | graph: graph}
  end

  defp animate_bullets(%State{graph: graph, bullets: bullets} = state) do
    graph =
      bullets
      |> Enum.reduce(graph, fn
        {:delete, id}, graph ->
          IO.puts("Deleting bullet!")
          Graph.delete(graph, id)

        bullet, graph ->
          IO.inspect(bullet, label: "bullet")

          graph
          |> Graph.modify(bullet.id, build_render_bullet(bullet))
      end)

    %{state | graph: graph}
  end

  defp animate_collision_boxes(%State{asteroids: asteroids, graph: graph} = state) do
    graph =
      asteroids
      |> Enum.map(&Play.CollisionBox.from/1)
      |> Enum.reduce(graph, fn
        %CollisionBox{} = collision_box, graph ->
          case Graph.get(graph, collision_box.id) do
            [] ->
              render_collision_box(graph, collision_box)

            [_] ->
              graph
              |> Graph.modify(collision_box.id, build_render_collision_box(collision_box))
          end

        {:delete, id}, graph ->
          IO.puts "Deleting collision box!"
          id = CollisionBox.id(id)
          Graph.delete(graph, id)
      end)

    %{state | graph: graph}
  end

  defp tick_asteroids(%State{asteroids: asteroids} = state) do
    asteroids = Enum.map(asteroids, &Play.Asteroid.tick/1)
    %{state | asteroids: asteroids}
  end

  defp tick_bullets(%State{bullets: bullets} = state) do
    bullets = Enum.map(bullets, &Play.Bullet.tick/1)
    %{state | bullets: bullets}
  end

  defp remove_dead_bullets(%State{bullets: bullets} = state) do
    bullets =
      bullets
      |> Enum.reject(fn
        {:delete, _} -> true
        _ -> false
      end)

    %{state | bullets: bullets}
  end

  defp remove_dead_asteroids(%State{asteroids: asteroids} = state) do
    %{state | asteroids: Enum.reject(asteroids, & match?({:delete, _}, &1))}
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
    restart()

    {:noreply, state}
  end

  def do_handle_input({:key, {key, action, _}}, _viewport_context, state)
      when key in @keys_to_track and action in [:press, :repeat, :release] do
    state = record_key_state(state, key, action)

    {:noreply, state}
  end

  def do_handle_input(_input, _, state) do
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

  @spec try_to_shoot(%State{}) :: %State{}
  defp try_to_shoot(state) do
    cond do
      shot_recently?(state) -> state
      length(state.bullets) >= @max_bullets -> state
      true -> shoot(state)
    end
  end

  @spec shoot(%State{}) :: %State{}
  defp shoot(state) do
    %{bullets: bullets, graph: graph, player_coords: player_coords} = state
    IO.puts("pew pew #{length(bullets)}")

    bullet = Play.Bullet.new(player_coords)
    graph = render_bullet(graph, bullet)

    %{state | bullets: [bullet | bullets], graph: graph, last_shot: state.t}
  end

  defp render_asteroid(graph, asteroid) do
    circle(graph, asteroid.size, id: asteroid.id, stroke: {3, asteroid.color}, t: asteroid.t)
  end

  defp build_render_bullet(bullet) do
    fn graph -> render_bullet(graph, bullet) end
  end

  defp build_render_collision_box(collision_box) do
    fn graph -> render_collision_box(graph, collision_box) end
  end

  defp render_bullet(graph, bullet) do
    circle(graph, bullet.size, id: bullet.id, t: bullet.t, stroke: {1, :white})
  end

  defp render_collision_box(graph, collision_box) do
    size = collision_box.size
    rectangle(graph, {size, size}, id: collision_box.id, t: collision_box.t, stroke: {1, :white})
  end

  defp schedule_animations do
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

    min_height = 0
    max_height = Play.Utils.screen_height() - player_height

    {constrain(width, min_width, max_width), constrain(height, min_height, max_height)}
  end

  defp constrain(value, min, max) do
    value
    |> min(max)
    |> max(min)
  end

  defp update_state_based_on_keys(%State{} = state) do
    %{key_states: key_states} = state

    key_states
    |> Enum.reduce(state, fn
      {key, _key_state}, state when key in @movement_keys ->
        direction = key_to_direction(key)
        update_player_coords(state, direction)

      {key, _key_state}, state when key in @firing_keys ->
        try_to_shoot(state)
    end)
  end

  defp shot_recently?(%State{last_shot: :never}), do: false

  defp shot_recently?(%State{last_shot: last_shot, t: t}) do
    t - last_shot < 4
  end

  defp check_collisions(%State{t: t} = state) when rem(t, 5) == 0 do
    collisions(state)
    |> Enum.reduce(state, &handle_collision/2)
  end

  defp check_collisions(state), do: state

  defp handle_collision({:player, :asteroid}, state), do: raise("Boom")

  defp handle_collision(
         {:bullet, %Bullet{id: bullet_id}, :asteroid, %CollisionBox{entity_id: asteroid_id}},
         state
       ) do
    asteroids =
      Enum.map(state.asteroids, fn
        %Asteroid{id: ^asteroid_id} -> {:delete, asteroid_id}
        asteroid -> asteroid
      end)

    bullets =
      Enum.map(state.bullets, fn
        %Bullet{id: ^bullet_id} -> {:delete, bullet_id}
        bullet -> bullet
      end)

    %{state | asteroids: asteroids, bullets: bullets}
  end

  defp handle_collision(_, state), do: state

  defp collisions(%State{graph: graph} = state) do
    %{asteroids: asteroids, player_coords: player_coords} = state

    asteroids
    |> Enum.flat_map(fn asteroid ->
      collision_box = Play.CollisionBox.from(asteroid)

      Enum.concat([
        player_collisions(player_coords, collision_box),
        bullet_collisions(state.bullets, collision_box)
      ])
    end)
  end

  defp player_collisions(player_coords, collision_box) do
    if collides?(player_coords, collision_box) do
      [{:player, :asteroid}]
    else
      []
    end
  end

  defp bullet_collisions(bullets, collision_box) do
    bullets
    |> Enum.flat_map(fn bullet ->
      if collides?(bullet.t, collision_box) do
        [{:bullet, bullet, :asteroid, collision_box}]
      else
        []
      end
    end)
  end

  @spec collides?(coords, Play.CollisionBox.t()) :: boolean
  defp collides?({width, height}, %Play.CollisionBox{} = collision_box) do
    {box_width, box_height} = collision_box.t

    overlap_x = overlap(width, box_width, box_width + collision_box.size)
    overlap_y = overlap(height, box_height, box_height + collision_box.size)

    overlap_x && overlap_y
  end

  defp overlap(x, x1, x2), do: x > x1 && x < x2

  def handle_call(:reload_current_scene, _, state), do: restart()

  defp initial_player_coordinates do
    width = Play.Utils.screen_width() / 2
    height = Play.Utils.screen_height() / 2
    {width, height}
  end

  defp restart, do: Process.exit(self(), :kill)
end
