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

  def id(entity_id), do: entity_id <> "_collision_box"

  # TODO: Change this to a protocol
  def from(%Play.Asteroid{t: {width, height}, size: size, id: entity_id}) do
    %__MODULE__{
      id: id(entity_id),
      entity_id: entity_id,
      t: {width - size, height - size},
      size: size * 2
    }
  end

  def from({:delete, id}), do: {:delete, id}
end
