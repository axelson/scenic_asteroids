defmodule Play.PlayerController do
  @moduledoc """
  GenServer that coordinates the control of a player

  Allows the player 10 seconds to reconnect in case they lose internet or
  refresh the page. If multiple people are controlling a player than their
  commands will be serialized an instance of this GenServer.

  If this GenServer dies the player should die.
  """

  use GenServer, restart: :transient
  require Logger

  defmodule State do
    @moduledoc false
    defstruct [
      :action_states,
      :action_timers,
      :direction,
      :username,
      :reconnect_timer,
      :connected?
    ]

    @type t :: %__MODULE__{
            action_states: %{required(atom) => true},
            action_timers: %{required(atom) => reference},
            direction: Play.Scene.Asteroids.direction(),
            username: Play.Scene.Asteroids.username(),
            reconnect_timer: reference,
            connected?: boolean
          }
  end

  defmodule View do
    @moduledoc """
    A view of the current state of the player's controller
    """

    defstruct [:actions, :direction]

    @type t :: %__MODULE__{
            actions: [atom],
            direction: Play.Scene.Asteroids.direction()
          }
  end

  @action_shoot :shoot
  @action_up :up
  @action_right :right
  @action_down :down
  @action_left :left
  @actions [
    @action_shoot,
    @action_up,
    @action_right,
    @action_down,
    @action_left,
    :rotate_left,
    :rotate_right
  ]

  # Amount of time in ms that an action is valid for before being cleared
  @action_clear_timeout 1_000
  # Amount of time that a user has to reconnect before the player is considered dead
  @reconnect_timeout 2_000

  def start_link(opts \\ []) do
    username = Keyword.fetch!(opts, :username)
    Logger.debug("player controller for #{username} starting")
    GenServer.start_link(__MODULE__, opts, name: process_name(username))
  end

  @impl GenServer
  def init(opts) do
    username = Keyword.fetch!(opts, :username)

    state = %State{
      action_states: %{},
      action_timers: %{},
      direction: {1, 0},
      username: username,
      connected?: true
    }

    {:ok, state}
  end

  def start_in_supervisor(username) do
    DynamicSupervisor.start_child(
      Play.PlayerControllerSupervisor,
      {Play.PlayerController, username: username}
    )
    |> case do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
    end
  end

  def register(username) do
    GenServer.cast(process_name(username), :register)
  end

  ########
  # Client
  ########
  def set_action(username, action) when is_binary(username) and action in @actions do
    GenServer.call(process_name(username), {:set_action, action})
  end

  def clear_action(username, action) when action in @actions do
    GenServer.call(process_name(username), {:clear_action, action})
  end

  def set_direction(username, direction) when is_binary(username) do
    if valid_direction(direction) do
      GenServer.call(process_name(username), {:set_direction, direction})
    end
  end

  def notify_connect(username) when is_binary(username) do
    GenServer.call(process_name(username), :notify_connect)
  end

  defp valid_direction({x, y}) when x <= 1 and y <= 1 and x >= -1 and y >= -1, do: true

  # TODO: Change this from a GenServer.call to ETS (for performance)
  def get_view(username) do
    if Registry.lookup(:player_controllers, username) != [] do
      GenServer.call(process_name(username), :get_view)
    else
      {:error, :dead}
    end
  end

  ########
  # Server
  ########

  @impl GenServer
  def handle_call({:set_action, action}, _from, state) when action in @actions do
    %State{action_states: action_states, action_timers: action_timers} = state

    action_timers =
      clear_timer_if_set(action_timers, action)
      |> Map.put(
        action,
        Process.send_after(self(), {:clear_action, action}, @action_clear_timeout)
      )

    action_states = Map.put(action_states, action, true)

    state = %State{state | action_states: action_states, action_timers: action_timers}

    {:reply, :ok, state}
  end

  def handle_call({:set_action, action}, _from, state) do
    reason = "Unable to handle action: #{inspect(action)}"
    Logger.warn(reason)
    {:stop, reason, {:error, reason}, state}
  end

  def handle_call({:clear_action, action}, _from, state) when action in @actions do
    state = do_clear_action(state, action)
    {:reply, :ok, state}
  end

  def handle_call({:clear_action, action}, _from, state) do
    reason = "Unable to handle clear action: #{inspect(action)}"
    Logger.warn(reason)
    {:stop, reason, state}
  end

  def handle_call({:set_direction, direction}, _from, state) do
    state = %State{state | direction: direction}
    {:reply, :ok, state}
  end

  def handle_call(:notify_connect, {from_pid, _}, state) do
    %State{reconnect_timer: reconnect_timer} = state

    if reconnect_timer do
      # IO.puts("PlayerController (#{state.username}): cancelling reconnect timer")
      Process.cancel_timer(reconnect_timer)
    end

    # We monitor the connected process because if that process dies, then if no new
    # conections come in then we kill ourselves
    Process.monitor(from_pid)

    state = %State{state | reconnect_timer: nil, connected?: true}
    {:reply, :ok, state}
  end

  def handle_call(:get_view, _from, state) do
    %State{action_states: action_states, direction: direction} = state

    actions =
      Enum.flat_map(action_states, fn
        {action, true} -> [action]
        _ -> []
      end)
      |> maybe_add_death_spin(state)

    view = %View{actions: actions, direction: direction}

    {:reply, view, state}
  end

  defp maybe_add_death_spin(actions, state) do
    %State{connected?: connected?} = state

    cond do
      connected? -> actions
      Enum.any?(actions, :rotate_right) -> actions
      true -> [:rotate_right | actions]
    end
  end

  @impl GenServer
  def handle_cast(:register, state) do
    # IO.puts("#{state.username} registering! in pid #{inspect(self())}")
    GenServer.call(Play.Scene.Asteroids, {:register_player, state.username, self()})
    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:clear_action, action}, state) when action in @actions do
    state = do_clear_action(state, action)
    {:noreply, state}
  end

  def handle_info({:clear_action, action}, state) do
    reason = "Unable to handle clear action: #{inspect(action)}"
    Logger.warn(reason)
    {:stop, reason, state}
  end

  def handle_info({:DOWN, _ref, :process, _pid, _reason}, state) do
    %State{reconnect_timer: reconnect_timer} = state
    # IO.puts("PlayerController (#{state.username}): PROCESS DOWN! #{inspect(pid)}")

    timer =
      unless reconnect_timer do
        # IO.puts("PlayerController (#{state.username}): reconnect timer set")
        Process.send_after(self(), :reconnect_timer_expired, @reconnect_timeout)
      end

    state = %State{state | reconnect_timer: timer, connected?: false}
    {:noreply, state}
  end

  def handle_info(:reconnect_timer_expired, state) do
    Logger.warn(
      "PlayerController (#{state.username}): shutting down due to reconnect_timer expiring"
    )

    {:stop, :normal, state}
  end

  def handle_info(event, state) do
    Logger.warn("Unhandled event: #{inspect(event)}")
    {:noreply, state}
  end

  defp do_clear_action(%State{} = state, action) do
    %State{action_states: action_states, action_timers: action_timers} = state

    action_states = Map.drop(action_states, [action])
    action_timers = clear_timer_if_set(action_timers, action)

    %State{state | action_states: action_states, action_timers: action_timers}
  end

  defp clear_timer_if_set(action_timers, action) do
    case Map.fetch(action_timers, action) do
      {:ok, timer_ref} ->
        Process.cancel_timer(timer_ref)
        Map.drop(action_timers, [action])

      _ ->
        action_timers
    end
  end

  defp process_name(username), do: {:via, Registry, {:player_controllers, username}}
end
