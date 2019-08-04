defmodule PlayWeb.LobbyChannel do
  use Phoenix.Channel

  def join("lobby", _message, socket) do
    # Allow everyone to join
    {:ok, socket}
  end

  def handle_in(event, msg, socket) do
    IO.puts("Unhandled event: #{event} with message: #{inspect(msg)}")
    {:noreply, socket}
  end
end
