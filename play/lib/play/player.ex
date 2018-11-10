defmodule Play.Player do
  @moduledoc """
  Represents the player
  """
  defstruct [:id, :t, :direction]

  alias Play.Player

  @type t :: %__MODULE__{
          id: Play.ScenicEntity.id(),
          t: Play.Scene.Asteroids.coords(),
          direction: Play.Scene.Asteroids.direction()
        }

  @player_dimensions {{0, 0}, {-10, 30}, {10, 30}}

  def new() do
    %__MODULE__{
      id: :player,
      t: initial_player_coordinates(),
      direction: 0
    }
  end

  defp initial_player_coordinates do
    width = Play.Utils.screen_width() / 2
    height = Play.Utils.screen_height() / 2
    {width, height}
  end

  # Only expose temporarily
  def player_dimensions, do: @player_dimensions

  defimpl Play.ScenicEntity, for: __MODULE__ do
    def id(%Player{id: id}), do: id

    def tick(%Player{} = player), do: player

    def draw(%Player{} = player, graph) do
      Scenic.Primitives.triangle(graph, Player.player_dimensions(),
        id: player.id,
        t: player.t,
        rotate: Play.Utils.scenic_radians(player.direction),
        stroke: {1, :white}
      )
    end
  end
end
