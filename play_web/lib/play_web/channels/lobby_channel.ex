defmodule PlayWeb.LobbyChannel do
  use Phoenix.Channel
  alias PlayWeb.Presence

  @impl Phoenix.Channel
  def join("lobby", _message, socket) do
    with {:ok, username} <- PlayWeb.UserSocket.logged_in_username(socket),
         {:ok, _} <- Registry.register(Registry.Usernames, username, self()),
         :ok = start_player_controller(username),
         :ok = Play.PlayerController.notify_connect(username) do
      send(self(), :after_join)
      {:ok, socket}
    else
      {:error, {:already_registered, _}} ->
        {:error, %{reason: :username_taken}}

      {:error, error} ->
        {:error, %{reason: translate_error(error)}}
    end
  end

  defp start_player_controller(username) do
    Play.PlayerController.start_in_supervisor(username, self())
  end

  def handle_in("player_direction", msg, socket) do
    action = direction_to_action(msg["direction"])
    :ok = Play.PlayerController.set_action(username(socket), action)
    {:noreply, socket}
  end

  def handle_in("clear_player_direction", msg, socket) do
    IO.inspect(msg, label: "msg")
    action = direction_to_action(msg["direction"])
    :ok = Play.PlayerController.clear_action(username(socket), action)
    {:noreply, socket}
  end

  def handle_in("try_shoot", _msg, socket) do
    :ok = Play.PlayerController.set_action(username(socket), :shoot)
    {:noreply, socket}
  end

  def handle_in("try_shoot_direction", msg, socket) do
    %{"x" => x, "y" => y} = msg
    :ok = Play.PlayerController.set_action(username(socket), :shoot)
    direction = Scenic.Math.Vector2.normalize({x, y})
    :ok = Play.PlayerController.set_direction(username(socket), direction)
    {:noreply, socket}
  end

  def handle_in("clear_shooting", msg, socket) do
    Play.PlayerController.clear_action(username(socket), :shoot)
    {:noreply, socket}
  end

  def handle_in(event, msg, socket) do
    IO.puts("Unhandled event: #{event} with message: #{inspect(msg)}")
    IO.inspect(socket, label: "socket")
    {:noreply, socket}
  end

  @impl Phoenix.Channel
  def handle_info(:after_join, socket) do
    push(socket, "presence_state", Presence.list(socket))

    {:ok, _} =
      Presence.track(socket, socket.assigns.username, %{
        online_at: inspect(System.system_time(:second))
      })

    {:noreply, socket}
  end

  defp direction_to_action("up"), do: :up
  defp direction_to_action("right"), do: :right
  defp direction_to_action("down"), do: :down
  defp direction_to_action("left"), do: :left

  defp username(socket) do
    {:ok, username} = PlayWeb.UserSocket.logged_in_username(socket)
    username
  end

  defp translate_error(:not_logged_in), do: "Not logged in"
  defp translate_error(:username_taken), do: "Username already taken"
  defp translate_error(:unknown_error), do: "An unknown error occurred"
end
