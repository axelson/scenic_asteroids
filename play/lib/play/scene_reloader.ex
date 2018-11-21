defmodule Play.SceneReloader do
  @moduledoc """
  A simple, generic code reloader for Scenic Scenes
  """
  use GenServer

  defmodule State do
    @moduledoc false
    defstruct [:viewport, :root]
  end

  def start_link(state) do
    IO.inspect(state, label: "start_link state")

    GenServer.start_link(__MODULE__, state)
  end

  def set_viewport(viewport) do
    GenServer.cast(__MODULE__, {:set_viewport, viewport})
  end

  @impl GenServer
  def init(_) do
    IO.puts("SceneReloader running #{inspect(self())}")
    true = Process.register(self(), __MODULE__)

    state = %State{}

    {:ok, state}
  end

  @impl GenServer
  def handle_call(:reload_current_scene, _, state) do
    IO.puts("Reloading current scene!")
    %State{viewport: viewport} = state
    Scenic.ViewPort.request_root(viewport, self())
    # GenServer.call(Play.Scene.Asteroids, :reload_current_scene)
    # Process.exit(viewport, :kill)

    {:reply, nil, state}
  end

  def handle_call({:set_root, root_scene}, _, state) do
    IO.inspect(root_scene, label: "root_scene")

    {:reply, nil, state}
  end

  def handle_call(:get_root, _, state) do
    {:reply, state, state}
  end

  def handle_call(call, _, state) do
    IO.inspect(call, label: "handle_call call")

    {:reply, nil, state}
  end

  @impl GenServer
  def handle_cast({:set_viewport, viewport}, state) do
    IO.puts("Received viewport")

    IO.inspect(viewport, label: "viewport")
    {:noreply, %{state | viewport: viewport}}
  end

  def handle_cast({:set_root, {:graph, graph, _} = root}, state) do
    IO.puts("Got set_root!")
    IO.inspect(graph, label: "graph")

    scene_pids()
    |> Enum.each(fn
      {:ok, pid} ->
        IO.inspect(pid, label: "pid")
        Process.exit(pid, :kill)

      _ ->
        IO.puts("unable to find!")
        nil
    end)

    {:noreply, %{state | root: root}}
  end

  def handle_cast(call, state) do
    IO.inspect(call, label: "handle_cast call")

    {:noreply, state}
  end

  # WARNING: This uses a private Scenic API
  defp scene_pids() do
    scenes_table = Scenic.ViewPort.Tables.scenes_table()

    :ets.match_object(scenes_table, :"$1")
    |> Enum.map(fn {_ref, registration} -> scene_pid(registration) end)
  end

  defp scene_pid({scene_pid, _child_pid, _supervisor_pid}) do
    {:ok, scene_pid}
  end

  defp scene_pid(other), do: {:error, :not_found}
end
