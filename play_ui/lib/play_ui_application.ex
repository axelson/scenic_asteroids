defmodule PlayUiApplication do
  @moduledoc """
  Starter application using the Scenic framework.
  """

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # load the viewport configuration from config
    main_viewport_config = Application.get_env(:play, :viewport)

    children = [
      {ScenicLiveReload, viewports: [main_viewport_config]}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
