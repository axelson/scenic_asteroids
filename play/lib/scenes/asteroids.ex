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
  alias Play.Player
  alias Play.PlayerController

  @type game_time :: integer
  @type coords :: {width :: integer, height :: integer}
  @type unit_vector :: {float, float}
  @type direction :: unit_vector
  @type username :: String.t()

  defmodule State do
    @moduledoc false
    defstruct [
      :asteroids,
      :player_bullets,
      :player_scores,
      :paused,
      :live_players,
      :dead_players,
      :player_pid_refs,
      :time,
      :graph,
      :viewport
    ]

    @type t :: %__MODULE__{
            asteroids: list(Play.Asteroid.t()),
            player_bullets: %{Play.Scene.Asteroids.username() => [Play.Bullet.t()]},
            player_scores: %{Play.Scene.Asteroids.username() => non_neg_integer()},
            paused: boolean,
            live_players: [Play.Player.t()],
            dead_players: [Play.Player.t()],
            player_pid_refs: %{reference => Play.Scene.Asteroids.username()},
            time: Play.Scene.Asteroids.game_time(),
            graph: Scenic.Graph.t(),
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

  @movement_actions [:up, :right, :down, :left, :rotate_left, :rotate_right]

  # Max bullets that each player can have on-screen at once
  @player_max_bullets 5
  @new_asteroid_chance_per_second 0.3
  @console_player_username "console"

  @initial_graph Graph.build()
                 # Rectangle used for capturing input for the scene
                 |> rect({Play.Utils.screen_width(), Play.Utils.screen_height()})
                 |> text("Score: 0",
                   id: :score,
                   t: {Play.Utils.screen_width(), 15},
                   fill: :white,
                   font: :roboto_mono,
                   text_align: :right
                 )
                 |> Launcher.HiddenHomeButton.add_to_graph([])

  @paused_graph Graph.build()
                # Rectangle used for capturing input for the scene
                |> rect({Play.Utils.screen_width(), Play.Utils.screen_height()})
                |> text("Game Paused",
                  t: {Play.Utils.screen_width() / 2, Play.Utils.screen_height() / 2},
                  fill: :white,
                  text_align: :center
                )

  @impl Scenic.Scene
  def init(_args, scenic_opts) do
    # Logger.info("scenic_opts: #{inspect(scenic_opts)}")
    # IO.puts("\n\nAsteroids scene starting with pid: #{inspect(self())}")
    Process.register(self(), __MODULE__)
    schedule_animations()

    state = initial_state(scenic_opts)

    PlayerController.start_in_supervisor(@console_player_username)
    :ok = Play.PlayerController.notify_connect(@console_player_username)
    state = register_player(state, @console_player_username, self())

    Registry.select(Registry.Usernames, [{{:"$1", :"$2", :"$3"}, [], [{{:"$1", :"$2", :"$3"}}]}])
    |> Enum.each(fn {username, _, _pid} ->
      PlayerController.register(username)
    end)

    endpoint().broadcast("lobby", "game_start", %{})

    {:ok, state, push: @initial_graph}
  end

  defp initial_state(opts) do
    %State{
      asteroids: 1..7 |> Enum.map(fn _ -> new_asteroid() end),
      player_bullets: %{},
      player_scores: %{},
      paused: false,
      live_players: [],
      dead_players: [],
      player_pid_refs: %{},
      time: 0,
      graph: @initial_graph,
      viewport: Keyword.get(opts, :viewport)
    }
  end

  def player_alive(username) do
    GenServer.call(__MODULE__, {:player_alive, username})
  end

  def player_color(username) do
    GenServer.call(__MODULE__, {:player_color, username})
  end

  @impl Scenic.Scene
  def handle_call({:register_player, username, pid}, _from, state) do
    state = register_player(state, username, pid)

    {:reply, :ok, state}
  end

  def handle_call({:player_alive, username}, _from, state) do
    {:reply, player_alive?(state, username), state}
  end

  def handle_call({:player_color, username}, _from, state) do
    case get_player(state, username) do
      {:ok, player} -> {:reply, {:ok, player.color}, state}
      {:error, :not_found} = err -> {:reply, err, state}
    end
  end

  def handle_call(msg, _from, state) do
    Logger.warn("UNHANDLED handle_call: #{inspect(msg)}")
    {:noreply, state}
  end

  @impl Scenic.Scene
  def handle_info({:animate, _}, %{paused: true} = state), do: {:noreply, state}

  def handle_info({:animate, _expected_run_time}, state) do
    state =
      state
      |> update_players()
      # Tick updates our internal representation of state
      |> tick_time()
      |> tick_entities()
      |> maybe_add_asteroid()
      # Update the rendering of each element in the graph
      |> draw_entities()
      |> remove_dead_entities()
      |> check_collisions()
      |> update_score()
      |> check_game_over()

    %{graph: graph} = state

    # if rem(state.time, 100) == 0 do
    #   # IO.inspect(Graph.get!(graph, :_root_), label: "Graph.get!(graph, :_root_)")
    #   # IO.inspect(graph, label: "graph")
    #   # IO.inspect(state, label: "state")
    # end

    {:noreply, state, push: graph}
  end

  def handle_info({:DOWN, ref, :process, _pid, _reason}, state) do
    %State{player_pid_refs: player_pid_refs} = state
    username = Map.get(player_pid_refs, ref)
    state = player_died(state, username)

    {:noreply, state}
  end

  defp tick_time(%State{time: t} = state), do: %{state | time: t + 1}

  defp register_player(state, username, pid) do
    %State{
      live_players: live_players,
      player_bullets: player_bullets,
      player_scores: player_scores,
      player_pid_refs: player_pid_refs
    } = state

    ref = Process.monitor(pid)

    new_player = Play.Player.new(username)
    live_players = [new_player | live_players]

    player_bullets = Map.put(player_bullets, username, [])
    player_scores = Map.put(player_scores, username, 0)
    player_pid_refs = Map.put(player_pid_refs, ref, username)

    %State{
      state
      | live_players: live_players,
        player_bullets: player_bullets,
        player_scores: player_scores,
        player_pid_refs: player_pid_refs
    }
  end

  defp get_console_player(state) do
    get_player(state, @console_player_username)
  end

  defp get_player(%State{} = state, username) do
    %State{live_players: live_players, dead_players: dead_players} = state

    case Enum.find(live_players, fn player -> player.username == username end) do
      nil -> Enum.find(dead_players, fn player -> player.username == username end)
      player -> player
    end
    |> case do
      nil -> {:error, :not_found}
      player -> {:ok, player}
    end
  end

  defp player_alive?(state, username) do
    %State{live_players: live_players} = state

    Enum.any?(live_players, fn player -> player.username == username end)
  end

  defp player_died(state, username) do
    %State{live_players: live_players, dead_players: dead_players} = state

    case Enum.split_with(live_players, fn p -> p.username == username end) do
      {[player], players} ->
        %State{state | live_players: players, dead_players: [player | dead_players]}

      {[], _players} ->
        # Player is already dead
        state
    end
  end

  @spec draw_entities(State.t()) :: State.t()
  defp draw_entities(%State{} = state) do
    graph =
      entities(state)
      |> Enum.reduce(state.graph, fn entity, graph ->
        Play.ScenicRenderer.draw(entity, graph)
      end)

    %{state | graph: graph}
  end

  @spec entities(State.t()) :: [Play.ScenicEntity.entity()]
  defp entities(%State{} = state) do
    %State{live_players: live_players, dead_players: dead_players, player_bullets: player_bullets} =
      state

    dead_players = for p <- dead_players, do: {:delete, p.id}

    Enum.concat([
      live_players,
      dead_players,
      state.asteroids,
      # TODO: Re-enable this dynamically
      # Enum.map(state.asteroids, &Play.Collision.from(&1)),
      Enum.flat_map(player_bullets, fn {_, bullets} -> bullets end)
    ])
  end

  defp tick_entities(%State{} = state) do
    %State{asteroids: asteroids, player_bullets: player_bullets} = state

    player_bullets =
      Map.new(player_bullets, fn {username, bullets} ->
        {username, Enum.map(bullets, &Play.ScenicEntity.tick/1)}
      end)

    %State{
      state
      | asteroids: Enum.map(asteroids, &Play.ScenicEntity.tick/1),
        player_bullets: player_bullets
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

    direction = {maybe_negate(:rand.uniform()), maybe_negate(:rand.uniform())}
    speed = :rand.uniform(3)

    Play.Asteroid.new({x, y}, size, direction, speed)
  end

  defp maybe_negate(number) do
    if :rand.uniform(10) >= 5 do
      number
    else
      -number
    end
  end

  defp add_asteroid?(%State{asteroids: asteroids}) when length(asteroids) > 100, do: false

  defp add_asteroid?(%State{} = state) do
    %{time: t} = state
    fps = Play.GameTimer.speed()
    base_chance = @new_asteroid_chance_per_second / fps
    scaling_factor = :math.log2(t) / 100

    chance = base_chance + scaling_factor

    :rand.uniform() < chance
  end

  defp remove_dead_entities(%State{} = state) do
    %State{asteroids: asteroids, player_bullets: player_bullets} = state
    reject_dead = &match?({:delete, _}, &1)

    player_bullets = Play.Utils.map_value(player_bullets, &Enum.reject(&1, reject_dead))

    %State{
      state
      | asteroids: Enum.reject(asteroids, reject_dead),
        player_bullets: player_bullets
    }
  end

  @impl Scenic.Scene
  def filter_event(event, sec, state) do
    IO.inspect(event, label: "event")
    IO.inspect(sec, label: "sec")

    {:cont, event, state}
  end

  @impl Scenic.Scene
  def handle_input(input, _viewport_context, %State{paused: true} = state) do
    if unpause_from_input(input) do
      Logger.info("Unpausing from input: #{inspect(input)}")
      state = %State{state | paused: false}
      {:noreply, state}
    else
      {:noreply, state}
    end
  end

  def handle_input(input, viewport_context, state) do
    # IO.inspect(input, label: "#{__MODULE__} received input")
    # Logger.info("Received input: #{inspect input}")
    do_handle_input(input, viewport_context, state)
  end

  def do_handle_input({:key, {"H", :press, _}}, _viewport_context, state) do
    Launcher.switch_to_launcher(state.viewport)

    {:noreply, state}
  end

  def do_handle_input({:key, {"R", :press, _}}, _viewport_context, state) do
    restart()

    {:noreply, state}
  end

  def do_handle_input({:key, {key, action, _}}, _viewport_context, state)
      when key in @keys_to_track and action in [:press, :repeat, :release] do
    record_console_key_state(key, action)

    {:noreply, state}
  end

  def do_handle_input({:key, {"Q", :press, _}}, _viewport_context, _state) do
    System.stop(0)
  end

  def do_handle_input({:key, {"P", :press, _}}, _viewport_context, state) do
    Logger.info("Pausing by pressing P")
    state = pause(state)
    {:noreply, state, push: graph(state)}
  end

  def do_handle_input({:key, {"I", :press, _}}, _viewport_context, state) do
    IO.inspect(state.graph, label: "graph")
    {:noreply, state}
  end

  def do_handle_input({:key, {"G", :press, _}}, _viewport_context, state) do
    game_over(state)
    {:noreply, state}
  end

  # Mouse/Touchscreen drag input
  def do_handle_input({:cursor_pos, cursor_coords}, _viewport_context, state) do
    update_console_player_direction(state, cursor_coords)
    {:noreply, state}
  end

  # Mouse Click/Touchscreen tap input
  def do_handle_input({:cursor_button, {:left, key_action, _, _cursor_coords}}, _, state) do
    case key_action do
      :press -> PlayerController.set_action(@console_player_username, :shoot)
      :release -> PlayerController.clear_action(@console_player_username, :shoot)
      _ -> nil
    end

    {:noreply, state}
  end

  def do_handle_input(_input, _, state) do
    # IO.inspect(input, label: "#{__MODULE__} ignoring input")
    {:noreply, state}
  end

  defp record_console_key_state(key, key_action) do
    action = key_to_action(key)

    case key_action do
      :press -> :ok = PlayerController.set_action(@console_player_username, action)
      :release -> :ok = PlayerController.clear_action(@console_player_username, action)
      _ -> nil
    end
  end

  defp update_console_player_direction(%State{} = state, cursor_coords) do
    {:ok, player} = get_console_player(state)
    direction = Play.Utils.find_angle_to(player.t, cursor_coords)
    PlayerController.set_direction(player.username, direction)
  end

  @spec try_to_shoot(State.t(), Player.t()) :: State.t()
  defp try_to_shoot(state, player) do
    %State{player_bullets: player_bullets} = state
    bullets = Map.get(player_bullets, player.username)

    cond do
      player_shot_recently?(state, player) -> state
      length(bullets) >= @player_max_bullets -> state
      true -> player_shoot(state, player)
    end
  end

  @spec player_shoot(State.t(), Player.t()) :: %State{}
  defp player_shoot(state, player) do
    %State{player_bullets: player_bullets, time: time} = state
    bullets = Map.get(player_bullets, player.username)

    bullet = Play.Bullet.new(player)
    bullets = [bullet | bullets]
    player_bullets = Map.put(player_bullets, player.username, bullets)
    player = %Player{player | last_shot: time}

    %{state | player_bullets: player_bullets}
    |> update_player(player.username, player)
  end

  defp update_player(%State{} = state, username, player) do
    %State{live_players: live_players, dead_players: dead_players} = state

    live_players =
      Enum.map(live_players, fn
        %{username: ^username} -> player
        p -> p
      end)

    dead_players =
      Enum.map(dead_players, fn
        %{username: ^username} -> player
        p -> p
      end)

    %State{state | live_players: live_players, dead_players: dead_players}
  end

  defp update_player_direction(%State{} = state, username, direction) do
    {:ok, player} = get_player(state, username)
    player = %Player{player | direction: direction}
    update_player(state, player.username, player)
  end

  defp schedule_animations do
    pid = self()
    # Process.send_after(self(), :animate, 2)
    func = fn expected_run_time ->
      Process.send(pid, {:animate, expected_run_time}, [])
    end

    SchedEx.run_in(func, 1, repeat: true, time_scale: Play.GameTimer)
  end

  defp key_to_action("W"), do: :up
  defp key_to_action("A"), do: :left
  defp key_to_action("S"), do: :down
  defp key_to_action("D"), do: :right
  defp key_to_action(" "), do: :shoot

  defp pause(%State{} = state), do: %{state | paused: !state.paused}

  # NOTE: We fetch and udpate the player from the state in each iteration so
  # that each function can be completely independent from the next.
  defp update_players(%State{} = state) do
    %State{live_players: live_players} = state

    usernames = Enum.map(live_players, fn p -> p.username end)

    Enum.reduce(usernames, state, fn username, state ->
      case PlayerController.get_view(username) do
        {:error, :dead} ->
          # IO.puts("#{username} is dead!")
          state

        %PlayerController.View{actions: actions, direction: direction} ->
          state = update_player_direction(state, username, direction)

          # NOTE: Don't get the player outside of the loop because we changing
          # the user in the overall state each iteration
          Enum.reduce(actions, state, fn
            action, state when action in @movement_actions ->
              {:ok, player} = get_player(state, username)
              player = Player.tick_player_coords(player, action)

              # HACK! Bad performance!
              if action in [:rotate_left, :rotate_right] do
                PlayerController.set_direction(username, player.direction)
              end

              update_player(state, username, player)

            :shoot, state ->
              {:ok, player} = get_player(state, username)
              try_to_shoot(state, player)
          end)
      end
    end)
  end

  defp player_shot_recently?(%State{} = state, player) do
    %State{time: time} = state
    Player.shot_recently?(player, time)
  end

  defp check_collisions(%State{time: t} = state) when rem(t, 5) == 0 do
    collisions(state)
    |> Enum.reduce(state, &handle_collision/2)
  end

  defp check_collisions(state), do: state

  defp handle_collision(
         {:player, player, :asteroid, %CollisionBox{entity_id: asteroid_id}},
         %State{} = state
       ) do
    asteroids =
      Enum.map(state.asteroids, fn
        %Asteroid{id: ^asteroid_id} -> {:delete, asteroid_id}
        asteroid -> asteroid
      end)

    state = player_death(state, player)
    %State{state | asteroids: asteroids}
  end

  defp handle_collision(
         {:bullet, %Bullet{id: bullet_id}, :asteroid, %CollisionBox{entity_id: asteroid_id}},
         state
       ) do
    %State{player_scores: player_scores, player_bullets: player_bullets} = state

    asteroids =
      Enum.map(state.asteroids, fn
        %Asteroid{id: ^asteroid_id} -> {:delete, asteroid_id}
        asteroid -> asteroid
      end)

    # Find the player who owns the bullet
    username =
      Enum.find_value(player_bullets, fn {username, bullets} ->
        if Enum.any?(bullets, fn
             %Bullet{id: ^bullet_id} -> true
             {:delete, ^bullet_id} -> true
             _ -> false
           end) do
          username
        end
      end)

    player_scores = Map.update!(player_scores, username, fn score -> score + 1 end)

    player_bullets =
      Map.update!(player_bullets, username, fn bullets ->
        Enum.map(bullets, fn
          %Bullet{id: ^bullet_id} -> {:delete, bullet_id}
          bullet -> bullet
        end)
      end)

    %State{
      state
      | asteroids: asteroids,
        player_bullets: player_bullets,
        player_scores: player_scores
    }
  end

  defp handle_collision(_, state), do: state

  defp collisions(%State{} = state) do
    %State{asteroids: asteroids, player_bullets: player_bullets} = state

    asteroids
    |> Enum.flat_map(fn asteroid ->
      collision_box = Play.Collision.from(asteroid)
      bullets = Enum.flat_map(player_bullets, fn {_, bullets} -> bullets end)

      Enum.concat([
        players_collisions(state, collision_box),
        bullet_collisions(bullets, collision_box)
      ])
    end)
  end

  defp players_collisions(%State{} = state, collision_box) do
    %State{live_players: players} = state

    players
    |> Enum.flat_map(fn player ->
      if collides?(player.t, collision_box) do
        [{:player, player, :asteroid, collision_box}]
      else
        []
      end
    end)
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
    %State{graph: graph, player_scores: player_scores} = state

    score_messages =
      player_scores
      |> Enum.sort_by(fn {_, score} -> score end, &>=/2)
      |> Enum.map(fn {username, score} -> "#{username} - #{score}" end)
      |> Enum.join("\n")

    message = "Score:\n" <> score_messages

    graph = Graph.modify(graph, :score, &text(&1, message))
    %State{state | graph: graph}
  end

  defp check_game_over(%State{live_players: []} = state), do: game_over(state)
  defp check_game_over(%State{} = state), do: state

  defp player_death(%State{} = state, dieing_player) do
    # move the player from live to dead and remove the asteroid
    %State{live_players: live_players, dead_players: dead_players} = state

    live_players =
      Enum.reject(live_players, fn player -> player.username == dieing_player.username end)

    dead_players = [dieing_player | dead_players]
    %State{state | live_players: live_players, dead_players: dead_players}
  end

  defp game_over(state) do
    %State{player_scores: player_scores} = state
    IO.puts("Game lost!")

    width = Play.Utils.screen_width() / 2
    height = Play.Utils.screen_height() / 2
    coords = {width, height}

    Scenic.ViewPort.set_root(
      state.viewport,
      {Play.Scene.PlayerDeath, {coords, player_scores}}
    )

    state
  end

  defp unpause_from_input({:key, {"left_alt", :press, 0}}), do: false
  defp unpause_from_input({:cursor_button, {_, :press, _, _}}), do: true
  # Only unpause on key press (not release)
  defp unpause_from_input({:key, {_, :press, _}}), do: true
  defp unpause_from_input(_), do: false

  defp graph(%State{paused: true}), do: @paused_graph
  defp graph(%State{graph: graph}), do: graph

  defp overlap(x, x1, x2), do: x > x1 && x < x2

  defp restart, do: Process.exit(self(), :kill)

  defp endpoint, do: Application.fetch_env!(:play, :endpoint)
end
