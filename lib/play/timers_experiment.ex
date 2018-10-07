defmodule Play.TimersExperiment do
  def init do
    {:ok, supervisor_pid} = DynamicSupervisor.start_link(strategy: :one_for_one)
    # start_demo(supervisor_pid)
    start_minute_counter(supervisor_pid)
    # start_second_counter(supervisor_pid)
    second_counter_run_in()
  end

  def start_demo(supervisor_pid) do
    print = fn ->
      IO.puts "Hello timescale #{Timex.now()}"
    end
    SchedEx.run_every(print, "30 10 * * *", time_scale: TimeScale)
  end

  def start_minute_counter(supervisor_pid) do
    crontab = "*/1 * * * *"
    mfa = [IO, :puts, ["hello minute"], crontab]

    child = %{
      id: "scheduled-task-1",
      start: {SchedEx, :run_every, mfa}
      # start: {IO, :puts, ["hello"]}
    }

    result = DynamicSupervisor.start_child(supervisor_pid, child)
    IO.inspect(result, label: "Started minute counter")
  end

  def start_second_counter(supervisor_pid) do
    {:ok, agent} = Agent.start_link(fn -> 0 end)

    update_and_get = fn ->
      count =
        Agent.get_and_update(agent, fn second ->
          new = second + 1
          {new, new}
        end)

      IO.puts "Hello second #{count} #{inspect NaiveDateTime.utc_now()}"
    end

    opts = [time_scale: Play.GameTimer]
    crontab = "*/1 * * * *"
    # mfa = [IO, :puts, ["hello second"], crontab, opts]
    mfa = [update_and_get, crontab, opts]

    child = %{
      id: "scheduled-task-2",
      start: {SchedEx, :run_every, mfa}
      # start: {IO, :puts, ["hello"]}
    }

    result = DynamicSupervisor.start_child(supervisor_pid, child)
    IO.inspect(result, label: "Started second counter")
  end

  def second_counter_run_in() do
    func = fn -> IO.puts "count #{Timex.now()}" end
    SchedEx.run_in(func, 1, repeat: true, time_scale: TimeScale)
  end
end

defmodule Counter do
end

defmodule TimeScale do
  def now(tz) do
    Timex.now(tz)
  end

  def speedup do
    fps = 1
    speed = fps / 1000
    IO.inspect(speed, label: "speed")
    speed
  end
end
