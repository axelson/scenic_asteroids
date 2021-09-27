defmodule Play do
  @moduledoc """
  Starter application using the Scenic framework.
  """

  def start(_type, _args) do
    # start the application with the viewport
    children =
      [
        {DynamicSupervisor, name: Play.PlayerControllerSupervisor, strategy: :one_for_one},
        # Registry that keeps track of all users currently signed in to the system
        # to prevent duplicate logins
        {Registry, keys: :unique, name: Registry.Usernames},
        # Registry that tracks all of the `Play.PlayerController` GenServers and
        # associates them by player username
        {Registry, [keys: :unique, name: :player_controllers]},
        # Play.Demo,
        Play.ColorAssigner,
        maybe_start_scenic()
      ]
      |> List.flatten()

    Supervisor.start_link(children, strategy: :one_for_one)
  end

  if Mix.env() == :test do
    defp maybe_start_scenic, do: []
  else
    defp maybe_start_scenic do
      # load the viewport configuration from config
      main_viewport_config = Application.get_env(:play, :viewport)

      if main_viewport_config do
        [
          {Scenic, [main_viewport_config]}
        ]
      else
        []
      end
    end
  end
end
