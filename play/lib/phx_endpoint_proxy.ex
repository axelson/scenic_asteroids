defmodule Play.PhxEndpointProxy do
  def notify_game_start do
    phx_endpoint().broadcast("lobby", "game_start", %{})
  end

  defp phx_endpoint, do: Application.fetch_env!(:play, :phx_endpoint)
end
