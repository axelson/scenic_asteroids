defmodule Play.Scene.Asteroids do
  @moduledoc """
  Asteroids animation/game

  Scene is responsible for:
  * Rendering the graph
  * Tracking key strokes and reacting to them (such as player movement)
  * Rendering game state
  * Updating the graph

  Maybe should not be responsible for:
  * Checking collisions
  * Check if player is currently allowed to shoot
  * Ticking game state
  * Running the game loop

  Questions:
  * Who is responsible for knowing how to draw an entity? The entity or the
    Scene? Or is it simply a protocol specific to the medium?
  * Should tracking game state be done in a separate process from the drawing of
    the game state? It would allow us to draw the game state at any point even
    if computing the next state becomes expensive. But how do we transfer the
    state between the processes? Maybe a drawable version of the state needs to
    be sent from the game to the scene. Or maybe we should store the state in an
    ETS table so that we don't block in the GenServer at all. If the game is
    stored separately then we can render multiple views of it... Like a web one
  * Should we extract out a Game module?
  * Who is responsible for the game loop? The scene or the game? I'm leaning
    towards the game
  * Can I extract a GameEngine?
    * Can be rendered to Scenic or to a Canvas (via d3?)
  * Is the game a process or just a struct?

  Thoughts:
  * The scene is the view in MVC
  """

  use Scenic.Scene
  import Scenic.Primitives
  require Logger

  alias Scenic.Graph
  alias Play.Asteroid
  alias Play.Bullet
  alias Play.CollisionBox

  @type game_time :: integer
  @type coords :: {width :: integer, height :: integer}

  defmodule State do
    @moduledoc false
    defstruct [
      :time,
      :graph,
      :player_coords,
      :key_states,
      :bullets,
      :asteroids,
      :last_shot
    ]

    @type t :: %__MODULE__{
            time: Play.Scene.Asteroids.game_time(),
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
  # [x] Press 'q' to quit
  # [x] Create protocols
  # [x] Create more general Play.ScenicEntity protocol (instead of many specific
  #     protocols)
  # [ ] Clean up scene to essentials of a scene and not gameplay
  # [ ] Asteroid move in vectors
  # [ ] Asteroid randomization
  # [ ] Asteroid spawning
  # [ ] Asteroid demolition into pieces
  # [ ] Don't render on integer time, scale everything by time slices
  # [ ] Render circles where the mouse cusor is
  # [ ] Shoot bullets towards the mouse cursor
  # [ ] Tap on the screen to shoot

  # Question: Should there be a process per asteroid?
  # Answer: No!

  @movement_keys ["W", "A", "S", "D"]
  @firing_keys [" "]
  @keys_to_track @movement_keys ++ @firing_keys
  @max_bullets 5

  @player_dimensions {{0, 0}, {-10, 30}, {10, 30}}
  @initial_graph Graph.build()
                 |> triangle(@player_dimensions, id: :player, stroke: {1, :white})
                 |> rect({Play.Utils.screen_width(), Play.Utils.screen_height()})

  @impl Scenic.Scene
  def init(args, opts) do
    Logger.info("opts: #{inspect(opts)}")
    Process.register(self(), __MODULE__)
    push_graph(@initial_graph)
    schedule_animations()

    initial_state = %State{
      graph: @initial_graph,
      time: 0,
      player_coords: initial_player_coordinates(),
      key_states: %{},
      bullets: [],
      asteroids: [
        Play.Asteroid.new({100, 31}, 30),
        Play.Asteroid.new({100, 200}, 27),
        Play.Asteroid.new({100, 300}, 12)
      ],
      last_shot: :never
    }

    {:ok, initial_state}
  end

  def handle_info({:animate, _expected_run_time}, state) do
    state =
      state
      |> update_state_based_on_keys()
      # Tick updates our internal representation of state
      |> tick_time()
      |> tick_entities()
      |> check_collisions()
      # Update the rendering of each element in the graph
      |> draw_player()
      |> draw_entities()
      |> remove_dead_entities()

    %{graph: graph} = state
    push_graph(graph)

    # if rem(t, 100) == 0 do
    #   IO.inspect(graph, label: "graph")
    # end

    {:noreply, state}
  end

  defp tick_time(%State{time: t} = state), do: %{state | time: t + 1}

  defp draw_player(%State{graph: graph, player_coords: player_coords} = state) do
    graph = Graph.modify(graph, :player, &triangle(&1, @player_dimensions, t: player_coords))
    %{state | graph: graph}
  end

  @spec draw_entities(State.t()) :: State.t()
  defp draw_entities(%State{} = state) do
    graph =
      entities(state)
      |> Enum.reduce(state.graph, fn asteroid, graph ->
        Play.ScenicRenderer.draw(asteroid, graph)
      end)

    %{state | graph: graph}
  end

  @spec entities(State.t()) :: [Play.ScenicEntity.entity()]
  defp entities(%State{} = state) do
    Enum.concat([
      state.asteroids,
      Enum.map(state.asteroids, &Play.Collision.from(&1)),
      state.bullets
    ])
  end

  defp tick_entities(%State{} = state) do
    %{
      state
      | asteroids: Enum.map(state.asteroids, &Play.ScenicEntity.tick/1),
        bullets: Enum.map(state.bullets, &Play.ScenicEntity.tick/1)
    }
  end

  defp remove_dead_entities(%State{} = state) do
    reject_dead = &match?({:delete, _}, &1)
    %{state |
      asteroids: Enum.reject(state.asteroids, reject_dead),
      bullets: Enum.reject(state.bullets, reject_dead)
    }
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

  def do_handle_input({:key, {"Q", :press, _}}, _viewport_context, _state) do
    System.stop(0)
  end

  def do_handle_input({:key, {"I", :press, _}}, _viewport_context, state) do
    IO.inspect(state.graph, label: "graph")
    {:noreply, state}
  end

  def do_handle_input({:cursor_pos, cursor_pos}, _viewport_context, state) do
    radians = Play.Utils.find_angle_to(state.player_coords, cursor_pos)
    graph =
      Graph.modify(
        state.graph,
        :player,
        &triangle(&1, @player_dimensions, t: state.player_coords, rotate: radians)
      )

    push_graph(graph)

    {:noreply, %{state | graph: graph}}
  end

  def do_handle_input(input, _, state) do
    IO.inspect(input, label: "#{__MODULE__} ignoring input")
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
    %{bullets: bullets, player_coords: player_coords} = state
    IO.puts("pew pew #{length(bullets)}")

    bullet = Play.Bullet.new(player_coords)

    %{state | bullets: [bullet | bullets], last_shot: state.time}
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

    {
      Play.Utils.constrain(width, min_width, max_width),
      Play.Utils.constrain(height, min_height, max_height)
    }
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

  defp shot_recently?(%State{last_shot: last_shot, time: time}) do
    time - last_shot < 4
  end

  defp check_collisions(%State{time: t} = state) when rem(t, 5) == 0 do
    collisions(state)
    |> Enum.reduce(state, &handle_collision/2)
  end

  defp check_collisions(state), do: state

  defp handle_collision({:player, :asteroid}, _state), do: raise("Boom")

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

  defp collisions(%State{} = state) do
    %{asteroids: asteroids, player_coords: player_coords} = state

    asteroids
    |> Enum.flat_map(fn asteroid ->
      collision_box = Play.Collision.from(asteroid)

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
    |> Enum.flat_map(fn
      {:delete, _} ->
        []

      bullet ->
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

  def handle_call(:reload_current_scene, _, _state), do: restart()

  defp initial_player_coordinates do
    width = Play.Utils.screen_width() / 2
    height = Play.Utils.screen_height() / 2
    {width, height}
  end

  defp restart, do: Process.exit(self(), :kill)
end
