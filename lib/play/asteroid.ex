defmodule Play.Asteroid do
  @moduledoc """
  Represents an asteroid in the game
  """
  defstruct [:id, :t, :color, :size]

  alias Play.Asteroid

  @type t :: %__MODULE__{
          id: Play.ScenicEntity.id(),
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

  defimpl Play.ScenicEntity, for: __MODULE__ do
    def id(%Asteroid{id: id}), do: id

    def tick(%Asteroid{} = asteroid) do
      {width, height} = asteroid.t
      %{asteroid | t: {tick_width(asteroid, width), height}}
    end

    defp tick_width(%Asteroid{size: size} = _asteroid, width) do
      cond do
        width - size > Play.Utils.screen_width() -> -size
        true -> width + 1
      end
    end

    def draw(%Asteroid{} = asteroid, graph) do
      %{id: id, color: color, size: size, t: t} = asteroid
      Scenic.Primitives.circle(graph, size, id: id, stroke: {3, color}, t: t)
    end
  end

  defimpl Play.Collision, for: __MODULE__ do
    def from(%Asteroid{t: {width, height}, size: size, id: entity_id}) do
      %Play.CollisionBox{
        id: Play.CollisionBox.id(entity_id),
        entity_id: entity_id,
        t: {width - size, height - size},
        size: size * 2
      }
    end
  end
end
