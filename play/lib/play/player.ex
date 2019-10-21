defmodule Play.Player do
  @moduledoc """
  Represents the player
  """
  defstruct [:id, :t, :direction, :username, :color, :last_shot]

  alias Play.Player

  @type t :: %__MODULE__{
          id: Play.ScenicEntity.id(),
          t: Play.Scene.Asteroids.coords(),
          direction: Play.Scene.Asteroids.direction(),
          last_shot: Play.Scene.Asteroids.game_time(),
          color: any,
          username: String.t()
        }

  @player_dimensions {{0, 0}, {-10, 30}, {10, 30}}
  @rotate_actions [:rotate_left, :rotate_right]

  @player_distance_per_tick 5
  @time_between_shots 6

  @spec new(String.t()) :: t
  def new(username) do
    color = if username == "console", do: :white, else: Play.ColorAssigner.get_next_color()

    %__MODULE__{
      id: "player:#{username}",
      t: initial_player_coordinates(),
      last_shot: :never,
      username: username,
      color: color,
      direction: {1.0, 0.0}
    }
  end

  def tick_player_coords(%__MODULE__{} = player, action) do
    %__MODULE__{t: {width, height}} = player
    dist = @player_distance_per_tick

    if action in @rotate_actions do
      tick_rotation(player, action)
    else
      updated_coords =
        case action do
          :up -> {width, height - dist}
          :left -> {width - dist, height}
          :down -> {width, height + dist}
          :right -> {width + dist, height}
        end
        |> constrain_player_to_screen()

      %__MODULE__{player | t: updated_coords}
    end
  end

  @tick_turn_distance :math.pi() / 30
  defp tick_rotation(%__MODULE__{} = player, action) do
    direction = player.direction
    radians = Play.Utils.unit_vector_to_radians(direction)

    radians =
      case action do
        :rotate_left -> radians - @tick_turn_distance
        :rotate_right -> radians + @tick_turn_distance
      end

    new_direction = Play.Utils.radians_to_unit_vector(radians)

    %__MODULE__{player | direction: new_direction}
  end

  defp constrain_player_to_screen({width, height}) do
    {_, {player_width, _}, {_, player_height}} = player_dimensions()

    min_width = 0
    max_width = Play.Utils.screen_width() - player_width

    min_height = 0
    max_height = Play.Utils.screen_height() - player_height

    new_width = Play.Utils.constrain(width, min_width, max_width)
    new_height = Play.Utils.constrain(height, min_height, max_height)

    {new_width, new_height}
  end

  def shot_recently?(%__MODULE__{last_shot: :never}, _time), do: false

  def shot_recently?(%__MODULE__{last_shot: last_shot}, time) do
    time - last_shot < @time_between_shots
  end

  defp initial_player_coordinates do
    max_rand = 200
    rand_x = :rand.uniform(max_rand) - max_rand / 2
    rand_y = :rand.uniform(max_rand) - max_rand / 2

    width = Play.Utils.screen_width() / 2 + rand_x
    height = Play.Utils.screen_height() / 2 + rand_y
    {width, height}
  end

  def player_dimensions, do: @player_dimensions

  defimpl Play.ScenicEntity, for: Play.Player do
    def id(%Player{id: id}), do: id

    def tick(%Player{} = player), do: player

    def draw(%Player{} = player, graph) do
      Scenic.Primitives.triangle(graph, Player.player_dimensions(),
        id: player.id,
        t: player.t,
        rotate: Play.Utils.scenic_radians(player.direction),
        stroke: {1, player.color},
        fill: player.color
      )
    end
  end
end
