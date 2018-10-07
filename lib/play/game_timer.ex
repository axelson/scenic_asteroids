defmodule Play.GameTimer do
  @behaviour SchedEx.TimeScale
  @fps 60

  @impl true
  defdelegate now(timezone), to: SchedEx.IdentityTimeScale

  @impl true
  def speedup do
    60
  end

  def speed() do
    @fps
  end

  def delay do
    @fps
    #how many milliseconds in a second?
    #1000 ms in a s
    #1000 ms/s
    #60 fps/s
    #how many ms per frame (ms/f)
    #60 fps/s = 0.06 f/ms
    #16.667 ms/f
  end
end
