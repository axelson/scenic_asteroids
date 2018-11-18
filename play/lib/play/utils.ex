defmodule Play.Utils do
  @moduledoc """
  Misc utils
  """

  @spec make_id() :: Play.ScenicEntity.id()
  def make_id do
    10
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(padding: false)
  end

  def screen_width do
    # TODO: This should be moved to the play_ui project
    {width, _height} = Application.get_env(:play, :viewport)[:size]
    width
  end

  def screen_height do
    {_width, height} = Application.get_env(:play, :viewport)[:size]
    height
  end

  def constrain(value, min, max) do
    value
    |> min(max)
    |> max(min)
  end

  def scenic_radians(vector) do
    Scenic.Math.Vector2.normalize(vector)
    |> unit_vector_to_radians()
  end

  @doc """
  Find the angle in radians from pos1 to pos2
  """
  @spec find_angle_to(Play.Scene.Asteroids.coords(), Play.Scene.Asteroids.coords()) ::
          Play.Scene.Asteroids.direction()
  def find_angle_to(pos1, pos2) do
    {pos1_x, pos1_y} = pos1
    {pos2_x, pos2_y} = pos2

    # Steps:
    # Get vector from player to cursor using math
    # Adjust to flip the y coordinate to match math coordinates
    # Normalize the vector to a unit vector
    vector = {pos2_x - pos1_x, pos1_y - pos2_y}
    Scenic.Math.Vector2.normalize(vector)
  end

  # Directly above
  defp unit_vector_to_radians({0.0, 1.0}), do: 0

  # Directly below
  defp unit_vector_to_radians({0.0, -1.0}), do: :math.pi()

  defp unit_vector_to_radians({a, b}) when a <= 1.0 and b <= 1.0 do
    radians = :math.pi() / 2 - :math.atan(b / a)

    if a < 0 do
      radians + :math.pi()
    else
      radians
    end
  end
end
