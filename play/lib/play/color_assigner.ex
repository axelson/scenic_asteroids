defmodule Play.ColorAssigner do
  use GenServer

  @me __MODULE__
  @colors [
    :aqua,
    :chartreuse,
    :magenta,
    :gold,
    :salmon,
    :orange_red,
    :powder_blue
  ]

  def start_link(opts) do
    GenServer.start_link(@me, opts, name: @me)
  end

  @impl GenServer
  def init(opts) do
    {:ok, @colors}
  end

  def get_next_color, do: GenServer.call(@me, :get_next_color)

  @impl GenServer
  def handle_call(:get_next_color, _from, colors) do
    {[color], colors} = Enum.split(colors, 1)
    {:reply, color, maybe_refresh_colors(colors)}
  end

  defp maybe_refresh_colors([]), do: @colors
  defp maybe_refresh_colors(colors), do: colors
end
