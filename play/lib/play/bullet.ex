defmodule Play.Bullet do
  @moduledoc """
  Struct that represents a bullet in the game
  """
  alias Play.Bullet

  defstruct [:id, :t, :direction, :color, :size]

  @speed 5

  @type t :: %__MODULE__{
    id: Play.ScenicEntity.id(),
    t: Play.Scene.Asteroids.coords(),
    direction: Play.Scene.Asteroids.direction(),
    color: atom,
    size: integer
  }

  def new(%Play.Player{t: coords, direction: direction}) do
    %__MODULE__{
      id: Play.Utils.make_id(),
      t: coords,
      direction: direction,
      color: :white,
      size: 5
    }
  end

  def speed, do: @speed

  defimpl Play.ScenicEntity, for: __MODULE__ do
    def id(%Bullet{id: id}), do: id

    def tick(%Bullet{} = bullet) do
      alias Scenic.Math.Vector2

      %{direction: direction, t: current_pos} = bullet

      {dx, dy} = Vector2.mul(direction, Bullet.speed())
      # TODO: Handle the -dy conversion better
      new_pos = Vector2.add(current_pos, {dx, -dy})

      new_bullet = %{bullet | t: new_pos}

      if offscreen?(new_bullet) do
        {:delete, bullet.id}
      else
        new_bullet
      end
    end

    defp offscreen?(%Bullet{} = bullet) do
      {width, height} = bullet.t
      screen_width = Play.Utils.screen_width()
      screen_height = Play.Utils.screen_height()

      cond do
        width - bullet.size > screen_width -> true
        width + bullet.size < 0 -> true
        height - bullet.size > screen_height -> true
        height + bullet.size < 0 -> true
        true -> false
      end
    end

    def draw(%Bullet{} = bullet, graph) do
      %{id: id, size: size, t: t} = bullet
      Scenic.Primitives.circle(graph, size, id: id, t: t, stroke: {1, :white})
    end
  end
end
