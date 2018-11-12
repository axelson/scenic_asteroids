defmodule Play.Asteroid do
  @moduledoc """
  Represents an asteroid in the game
  """
  defstruct [:id, :t, :direction, :speed, :color, :size]

  alias Scenic.Math.Vector2
  alias Play.Asteroid

  @type t :: %__MODULE__{
          id: Play.ScenicEntity.id(),
          t: Play.Scene.Asteroids.coords(),
          direction: Play.Scene.Asteroids.direction(),
          speed: float,
          color: atom,
          size: integer
        }

  def new(coords, size, direction, speed) do
    %__MODULE__{
      id: Play.Utils.make_id(),
      t: coords,
      direction: Vector2.normalize(direction),
      speed: speed,
      color: :white,
      size: size
    }
  end

  defimpl Play.ScenicEntity, for: __MODULE__ do
    def id(%Asteroid{id: id}), do: id

    def tick(%Asteroid{} = asteroid) do
      %{asteroid | t: new_position(asteroid)}
    end

    def draw(%Asteroid{} = asteroid, graph) do
      %{id: id, color: color, size: size, t: t} = asteroid
      Scenic.Primitives.circle(graph, size, id: id, stroke: {3, color}, t: t)
    end

    defp new_position(%Asteroid{} = asteroid) do
      {x, y} = asteroid.t
      size = asteroid.size

      screen_width = Play.Utils.screen_width()
      screen_height = Play.Utils.screen_height()

      case offscreen(asteroid) do
        :north -> {x, screen_height + size}
        :east -> {0 - size, y}
        :south -> {x, 0 - size}
        :west -> {screen_width + size, y}
        :onscreen -> next_tick_onscreen_pos(asteroid)
      end
    end

    defp next_tick_onscreen_pos(%Asteroid{} = asteroid) do
      %{t: t, direction: direction, speed: speed} = asteroid
      Vector2.add(t, Vector2.mul(direction, speed))
    end

    defp offscreen(%Asteroid{} = asteroid) do
      {width, height} = asteroid.t
      screen_width = Play.Utils.screen_width()
      screen_height = Play.Utils.screen_height()

      cond do
        width - asteroid.size > screen_width -> :east
        width + asteroid.size < 0 -> :west
        height - asteroid.size > screen_height -> :south
        height + asteroid.size < 0 -> :north
        true -> :onscreen
      end
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
