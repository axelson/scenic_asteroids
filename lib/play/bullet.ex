defmodule Play.Bullet do
  @moduledoc """
  Struct that represents a bullet in the game
  """

  defstruct [:id, :t, :color, :size]

  @speed 5

  @type t :: %__MODULE__{
    id: reference(),
    t: Play.Scene.Asteroids.coords(),
    color: atom,
    size: integer
  }

  def new(coords) do
    %__MODULE__{
      id: make_ref(),
      t: coords,
      color: :white,
      size: 5
    }
  end

  @spec tick(%__MODULE__{}) :: %__MODULE__{} | :delete
  def tick(%__MODULE__{} = bullet) do
    {width, height} = bullet.t
    new_bullet = %{bullet | t: {width, height - @speed}}

    if offscreen?(new_bullet) do
      {:delete, bullet.id}
    else
      new_bullet
    end
  end

  def tick({:delete, _} = deleted), do: deleted

  defp offscreen?(%__MODULE__{} = bullet) do
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
end
