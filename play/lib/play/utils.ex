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
    # TODO: This should be passed in instead of stored in config
    {width, _height} = Application.get_env(:play, :viewport_size)
    width
  end

  def screen_height do
    {_width, height} = Application.get_env(:play, :viewport_size)
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

  def radians_to_unit_vector(radians) do
    {:math.sin(radians), :math.cos(radians)}
  end

  # Directly above
  def unit_vector_to_radians({0.0, 1.0}), do: 0

  # Directly below
  def unit_vector_to_radians({0.0, -1.0}), do: :math.pi()

  def unit_vector_to_radians({a, b}) when a <= 1.0 and b <= 1.0 do
    radians = :math.pi() / 2 - :math.atan(b / a)

    if a < 0 do
      radians + :math.pi()
    else
      radians
    end
  end

  def map_value(map, fun) when is_map(map) and is_function(fun, 1) do
    Map.new(map, fn {key, value} ->
      {key, fun.(value)}
    end)
  end

  def tap(term, func) when is_function(func, 1) do
    func.(term)
    term
  end

  defmacro input_state(:press) do
    quote do
      1
    end
  end

  defmacro input_state(:release) do
    quote do
      0
    end
  end

  defmacro input_state(:repeat) do
    quote do
      2
    end
  end

  defmacro add_log_input do
    quote do
      def handle_input(input, _context, scene) do
        require Logger
        Logger.warn("Ignoring input: #{inspect(input)}")
        {:noreply, scene}
      end
    end
  end
end
