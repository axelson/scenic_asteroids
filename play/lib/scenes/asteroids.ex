defmodule Play.Scene.Asteroids do
  @moduledoc """
  Asteroids animation/game

  Right now this module is like a God module, it knows and controls too much.

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
  @type unit_vector :: {float, float}
  @type direction :: unit_vector

  defmodule State do
    @moduledoc false
    defstruct [
      :asteroids,
      :bullets,
      :cursor_coords,
      :graph,
      :key_states,
      :last_shot,
      :num_asteroids_destroyed,
      :paused,
      :player,
      :time,
      :viewport
    ]

    @type t :: %__MODULE__{
            asteroids: list(Play.Asteroid.t()),
            bullets: list(Play.Bullet.t()),
            cursor_coords: Play.Scene.Asteroids.coords(),
            graph: Scenic.Graph.t(),
            key_states: %{required(String.t()) => true},
            last_shot: Play.Scene.Asteroids.game_time(),
            num_asteroids_destroyed: non_neg_integer,
            paused: boolean,
            player: Play.Player.t(),
            time: Play.Scene.Asteroids.game_time(),
            viewport: pid
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
  # [x] Track cursor pos in state
  # [x] Each frame, orient player to the cursor pos
  # [x] Add an explosion effect when the player collides with an asteroid
  # [ ] Clean up scene to essentials of a scene and not gameplay
  # [x] Asteroid move in vectors
  # [x] Asteroid randomization
  # [x] Asteroid spawning
  # [x] Shoot bullets towards the mouse cursor
  # [x] Tap on the screen to shoot
  # [x] Press 'p' to pause
  # [x] Time-based difficulty increasing
  # [ ] Press 'i' to show collision boxes

  # Question: Should there be a process per asteroid?
  # Answer: No!

  @movement_keys ["W", "A", "S", "D"]
  @firing_keys [" "]
  @keys_to_track @movement_keys ++ @firing_keys
  @max_bullets 5
  @new_asteroid_chance_per_second 0.3

  @initial_graph Graph.build()
                 # Rectangle used for capturing input for the scene
                 |> rect({Play.Utils.screen_width(), Play.Utils.screen_height()})
                 |> Play.Components.HiddenButton.add_to_graph({30, 30},
                   id: :pause_btn,
                   fill: :clear,
                   t: {Play.Utils.screen_width() - 30, 0}
                 )
                 |> text("Score: 0",
                   id: :score,
                   t: {Play.Utils.screen_width(), 15},
                   fill: :white,
                   font: :roboto_mono,
                   text_align: :right
                 )

  @impl Scenic.Scene
  def init(_args, scenic_opts) do
    # Logger.info("scenic_opts: #{inspect(scenic_opts)}")
    Process.register(self(), __MODULE__)
    push_graph(@initial_graph)
    schedule_animations()

    {:ok, initial_state(scenic_opts)}
  end

  defp initial_state(opts) do
    %State{
      asteroids: 1..7 |> Enum.map(fn _ -> new_asteroid() end),
      bullets: [],
      cursor_coords: {Play.Utils.screen_width() / 2, 0},
      graph: @initial_graph,
      key_states: %{},
      last_shot: :never,
      num_asteroids_destroyed: 0,
      paused: false,
      player: Play.Player.new(),
      time: 0,
      viewport: Keyword.get(opts, :viewport)
    }
  end

  def handle_info({:animate, _}, %{paused: true} = state), do: {:noreply, state}

  def handle_info({:animate, _expected_run_time}, state) do
    state =
      state
      |> update_state_based_on_keys()
      # Tick updates our internal representation of state
      |> tick_time()
      |> tick_entities()
      |> maybe_add_asteroid()
      |> update_player_direction()
      # Update the rendering of each element in the graph
      |> draw_entities()
      |> remove_dead_entities()
      |> check_collisions()
      |> update_score()

    %{graph: graph} = state
    push_graph(graph)

    # if rem(state.time, 100) == 0 do
    #   # IO.inspect(Graph.get!(graph, :_root_), label: "Graph.get!(graph, :_root_)")
    #   # IO.inspect(graph, label: "graph")
    #   # IO.inspect(state, label: "state")
    # end

    {:noreply, state}
  end

  defp tick_time(%State{time: t} = state), do: %{state | time: t + 1}

  @spec update_player_direction(State.t()) :: State.t()
  defp update_player_direction(%State{} = state) do
    %{player: player, cursor_coords: cursor_coords} = state
    direction = Play.Utils.find_angle_to(player.t, cursor_coords)

    %{state | player: %{player | direction: direction}}
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
      [state.player],
      state.asteroids,
      # TODO: Re-enable this dynamically
      # Enum.map(state.asteroids, &Play.Collision.from(&1)),
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

  defp maybe_add_asteroid(%State{} = state) do
    if add_asteroid?(state) do
      %{state | asteroids: [new_asteroid() | state.asteroids]}
    else
      state
    end
  end

  defp new_asteroid() do
    screen_width = Play.Utils.screen_width()
    screen_height = Play.Utils.screen_height()
    rand_x = :rand.uniform(screen_width)
    rand_y = :rand.uniform(screen_height)

    {min_size, max_size} = {10, 45}
    size = min_size + :rand.uniform(max_size - min_size)

    {x, y} =
      case Enum.random([:north, :east, :south, :west]) do
        :north -> {rand_x, 0 - size}
        :east -> {screen_width + size, rand_y}
        :south -> {rand_x, screen_height + size}
        :west -> {0 - size, rand_y}
      end

    direction = {:rand.uniform(), :rand.uniform()}
    speed = :rand.uniform(2)

    Play.Asteroid.new({x, y}, size, direction, speed)
  end

  defp add_asteroid?(%State{} = state) do
    %{time: t} = state
    fps = Play.GameTimer.speed()
    base_chance = @new_asteroid_chance_per_second / fps
    scaling_factor = :math.log2(t) / 400

    chance = base_chance + scaling_factor

    :rand.uniform() < chance
  end

  defp remove_dead_entities(%State{} = state) do
    reject_dead = &match?({:delete, _}, &1)

    %{
      state
      | asteroids: Enum.reject(state.asteroids, reject_dead),
        bullets: Enum.reject(state.bullets, reject_dead)
    }
  end

  @impl Scenic.Scene
  def filter_event({:click, :pause_btn}, _, %State{} = state) do
    state = pause(state)
    {:stop, state}
  end

  def filter_event(event, sec, state) do
    IO.inspect(event, label: "event")
    IO.inspect(sec, label: "sec")

    {:continue, event, state}
  end

  @impl Scenic.Scene
  def handle_input(input, viewport_context, state) do
    # IO.inspect(input, label: "#{__MODULE__} received input")
    # Logger.info("Received input: #{inspect input}")
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

  def do_handle_input({:key, {"P", :press, _}}, _viewport_context, state) do
    {:noreply, pause(state)}
  end

  def do_handle_input({:key, {"I", :press, _}}, _viewport_context, state) do
    IO.inspect(state.graph, label: "graph")
    {:noreply, state}
  end

  # Mouse/Touchscreen drag input
  def do_handle_input({:cursor_pos, cursor_coords}, _viewport_context, state) do
    {:noreply, update_cursor_coords(state, cursor_coords)}
  end

  # Mouse Click/Touchscreen tap input
  def do_handle_input(
        {:cursor_button, {:left, :press, _, cursor_coords}},
        _viewport_context,
        state
      ) do
    # TODO: Maybe we shouldn't handle this immediately but instead handle it in the animation loop
    state =
      state
      |> update_cursor_coords(cursor_coords)
      |> update_player_direction()
      |> try_to_shoot()

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

  @spec update_cursor_coords(%State{}, coords()) :: %State{}
  defp update_cursor_coords(state, cursor_coords) do
    %{state | cursor_coords: cursor_coords}
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
    %{bullets: bullets, player: player} = state
    IO.puts("pew pew #{length(bullets)}")

    bullet = Play.Bullet.new(player)

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

  defp pause(%State{} = state) do
    state = %{state | paused: !state.paused}
    push_graph(Graph.build())
    state
  end

  # TODO: Refactor this out of the scene
  # It is like ticking the player but it requires additional input
  # Maybe combine with update_player_direction func
  defp update_player_coords(%State{} = state, direction) do
    %{player: %{t: {width, height}}} = state
    dist = 5

    updated_coords =
      case direction do
        :up -> {width, height - dist}
        :left -> {width - dist, height}
        :down -> {width, height + dist}
        :right -> {width + dist, height}
      end
      |> constrain_player_to_screen()

    %{state | player: %{state.player | t: updated_coords}}
  end

  defp constrain_player_to_screen({width, height}) do
    {_, {player_width, _}, {_, player_height}} = Play.Player.player_dimensions()

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

  defp handle_collision({:player, :asteroid}, state), do: player_death(state)

  defp handle_collision(
         {:bullet, %Bullet{id: bullet_id}, :asteroid, %CollisionBox{entity_id: asteroid_id}},
         state
       ) do
    %{num_asteroids_destroyed: num_asteroids_destroyed} = state

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

    %{
      state
      | asteroids: asteroids,
        bullets: bullets,
        num_asteroids_destroyed: num_asteroids_destroyed + 1
    }
  end

  defp handle_collision(_, state), do: state

  defp collisions(%State{} = state) do
    %{asteroids: asteroids, player: %{t: player_coords}} = state

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

  defp update_score(%State{} = state) do
    %{graph: graph} = state
    score = score(state)
    graph = Graph.modify(graph, :score, &text(&1, "score: #{score}"))
    %{state | graph: graph}
  end

  defp player_death(state) do
    %{player: player, num_asteroids_destroyed: num_asteroids_destroyed} = state
    IO.puts("Player lost!")

    Scenic.ViewPort.set_root(
      state.viewport,
      {Play.Scene.PlayerDeath, {player.t, num_asteroids_destroyed}}
    )

    state
  end

  defp score(%State{num_asteroids_destroyed: n}), do: n

  defp overlap(x, x1, x2), do: x > x1 && x < x2

  def handle_call(:reload_current_scene, _, _state), do: restart()

  defp restart, do: Process.exit(self(), :kill)
end
