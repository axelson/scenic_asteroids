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
      {DynamicSupervisor, name: Play.PlayerControllerSupervisor, strategy: :one_for_one},
      # Registry that keeps track of all users currently signed in to the system
      # to prevent duplicate logins
      {Registry, keys: :unique, name: Registry.Usernames},
      # Registry that tracks all of the `Play.PlayerController` GenServers and
      # associates them by player username
      supervisor(Registry, [:unique, :player_controllers]),
      {Scenic, [main_viewport_config]},
      Play.Demo,
      Play.ColorAssigner
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
