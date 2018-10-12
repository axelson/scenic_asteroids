defmodule Play.Bullet do
  defstruct [:id, :t, :color]

  def new(coords) do
    %__MODULE__{
      id: make_ref(),
      t: coords,
      color: :white
    }
  end

  def tick(%__MODULE__{} = bullet) do
    {width, height} = bullet.t
    %{bullet | t: {width, height - 1}}
  end
end
