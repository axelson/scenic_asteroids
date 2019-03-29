defmodule ScenicLiveReload.Application do
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      ScenicLiveReload
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
