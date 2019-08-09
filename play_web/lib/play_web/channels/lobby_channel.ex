defmodule PlayWeb.LobbyChannel do
  use Phoenix.Channel

  def join("lobby", message, socket) do
    salt = "user sel"
    token = message["token"]

    case Phoenix.Token.verify(socket, salt, token, max_age: 86400) do
      {:ok, username} ->
        socket =
          socket
          |> assign(:username, username)

        {:ok, socket}

      _ ->
        {:error, %{reason: "not authorized"}}
    end
  end

  def handle_in("player_direction", msg, socket) do
    send(Play.Scene.Asteroids, "action:#{msg["direction"]}")
    {:noreply, socket}
  end

  def handle_in("clear_player_direction", msg, socket) do
    IO.inspect(msg, label: "msg")
    send(Play.Scene.Asteroids, "action:clear_player_direction:#{msg["direction"]}")
    {:noreply, socket}
  end

  def handle_in("try_shoot", msg, socket) do
    %{"x" => x, "y" => y} = msg

    send(Play.Scene.Asteroids, {:try_shoot, x, y})
    {:noreply, socket}
  end

  def handle_in(event, msg, socket) do
    IO.puts("Unhandled event: #{event} with message: #{inspect(msg)}")
    IO.inspect(socket, label: "socket")
    {:noreply, socket}
  end
end
