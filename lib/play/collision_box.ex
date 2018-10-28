defmodule Play.CollisionBox do
  @moduledoc """
  Shows the collision box of an entity. For debug purposes
  """

  defstruct [:id, :entity_id, :t, :size]

  @type t :: %__MODULE__{
          id: Play.Utils.id(),
          entity_id: Play.Utils.id(),
          t: Play.Scene.Asteroids.coords(),
          size: integer
        }

  # TODO: Change this to a protocol
  def from(%Play.Asteroid{t: {width, height}, size: size, id: id}) do
    %__MODULE__{
      id: id <> "_collision_box",
      entity_id: id,
      t: {width - size, height - size},
      size: size * 2
    }
  end
end
