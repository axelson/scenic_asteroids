defmodule Play.Demo do
  use GenServer

  @names [
    "bob",
    "james"
  ]

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl GenServer
  def init(_) do
    Enum.each(@names, &start_player/1)
    {:ok, %{}}
  end

  def start_player(username) do
    Registry.register(Registry.Usernames, username, self())
    :ok = Play.PlayerController.start_in_supervisor(username)
    :ok = Play.PlayerController.notify_connect(username)
  end
end
