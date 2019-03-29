defmodule ScenicLiveReload.Private.GetScenePids do
  @moduledoc """
  WARNING: Relies on private scenic API's

  Allows you to get the PID's of the current scene. There is a proposal to
  create a private api for this functionality that has been discussed at:
  https://github.com/boydm/scenic_new/pull/19
  """

  def scene_pids do
    scenes_table = Scenic.ViewPort.Tables.scenes_table()

    :ets.match_object(scenes_table, :"$1")
    |> Enum.map(fn {_ref, registration} -> scene_pid(registration) end)
  end

  defp scene_pid({scene_pid, _child_pid, _supervisor_pid}) do
    {:ok, scene_pid}
  end

  defp scene_pid(_other), do: {:error, :not_found}
end
