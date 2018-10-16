defmodule Play.Asteroid do
  defstruct [:id, :t, :color, :size]

  def new(coords, size) do
    %__MODULE__{
      id: make_ref(),
      t: coords,
      color: :white,
      size: size
    }
  end

  def tick(%__MODULE__{} = asteroid) do
    {width, height} = asteroid.t
    %{asteroid | t: {tick_width(asteroid, width), height}}
  end

  def tick_width(%__MODULE__{} = asteroid, width) do
    cond do
      width > Play.Utils.screen_width() -> -100
      true -> width + 1
    end
  end
end
