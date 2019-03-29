defmodule ScenicLiveReload do
  @moduledoc """
  A simple, generic code reloader for Scenic Scenes
  """
  use GenServer
  require Logger

  defmodule State do
    @moduledoc false
    defstruct []
  end

  def start_link(state, name \\ __MODULE__) do
    GenServer.start_link(__MODULE__, state, name: name)
  end

  @impl GenServer
  def init(_) do
    Logger.debug("SceneReloader running #{inspect(self())}")

    state = %State{}

    {:ok, state}
  end

  @impl GenServer
  def handle_call(:reload_current_scene, _, state) do
    Logger.info("Reloading current scene!")
    reload_current_scenes()

    {:reply, nil, state}
  end

  defp reload_current_scenes do
    ScenicLiveReload.Private.GetScenePids.scene_pids()
    |> Enum.each(fn
      {:ok, pid} ->
        Process.exit(pid, :kill)

      _ ->
        Logger.warn("Unable to find any scene PID's to reload")
      nil
    end)
  end
end
