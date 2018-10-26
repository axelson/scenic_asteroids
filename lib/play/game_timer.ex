defmodule Play.GameTimer do
  @moduledoc """
  Uses `SchedEx` to control the timescale of the game
  """

  @behaviour SchedEx.TimeScale
  @fps 60
  @multiplier 1

  @impl true
  defdelegate now(timezone), to: SchedEx.IdentityTimeScale

  @impl true
  def speedup do
    @fps / 1000 * @multiplier
  end

  def speed do
    @fps
  end
end
