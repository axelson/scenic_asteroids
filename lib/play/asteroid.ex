defmodule Play.Asteroid do
  @moduledoc """
  Represents an asteroid in the game
  """

  defstruct [:id, :t, :color, :size]

  @type t :: %__MODULE__{
    id: Play.Utils.id(),
    t: Play.Scene.Asteroids.coords(),
    color: atom,
    size: integer
  }

  def new(coords, size) do
    %__MODULE__{
      id: Play.Utils.make_id(),
      t: coords,
      color: :white,
      size: size
    }
  end

  # TODO: Make tick into a protocol
  def tick(%__MODULE__{} = asteroid) do
    {width, height} = asteroid.t
    %{asteroid | t: {tick_width(asteroid, width), height}}
  end

  def tick({:delete, id}), do: {:delete, id}

  defp tick_width(%__MODULE__{size: size} = _asteroid, width) do
    cond do
      width - size > Play.Utils.screen_width() -> -size
      true -> width + 1
    end
  end
end
