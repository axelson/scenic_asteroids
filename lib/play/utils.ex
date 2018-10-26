defmodule Play.Utils do
  @moduledoc """
  Misc utils
  """

  def screen_width do
    {width, _height} = Application.get_env(:play, :viewport)[:size]
    width
  end

  def screen_height do
    {_width, height} = Application.get_env(:play, :viewport)[:size]
    height
  end
end
