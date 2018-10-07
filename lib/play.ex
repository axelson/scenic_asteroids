defmodule Play do
  @moduledoc """
  Starter application using the Scenic framework.
  """

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # load the viewport configuration from config
    main_viewport_config = Application.get_env(:play, :viewport)

    # start the application with the viewport
    children = [
      {DynamicSupervisor, name: Play.GameSupervisor, strategy: :one_for_one},
      supervisor(Play.Sensor.Supervisor, []),
      supervisor(Scenic, viewports: [main_viewport_config]),
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
