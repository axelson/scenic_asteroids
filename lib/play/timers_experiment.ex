defmodule Play.TimersExperiment do
  def init do
    start_timer()
  end

  def start_timer() do
    func = fn -> IO.puts "count #{Timex.now()}" end
    SchedEx.run_in(func, 1, repeat: true, time_scale: Play.GameTimer)
  end
end
