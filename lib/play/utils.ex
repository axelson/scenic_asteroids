defmodule Play.Utils do
  @moduledoc """
  Misc utils
  """

  @type id :: String.t()

  def make_id do
    10
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(padding: false)
  end

  def screen_width do
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

end
