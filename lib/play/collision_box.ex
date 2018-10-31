defmodule Play.CollisionBox do
  @moduledoc """
  Shows the collision box of an entity. Used to assist in finding collisions and
  can be shown for debug purposes.
  """

  defstruct [:id, :entity_id, :t, :size]

  @type t :: %__MODULE__{
          id: Play.Utils.id(),
          entity_id: Play.Utils.id(),
          t: Play.Scene.Asteroids.coords(),
          size: integer
        }

  def id(entity_id), do: entity_id <> "_collision_box"
end

defprotocol Play.Collision do
  @doc "Convert this data structure into a collision box"
  @spec from(any) :: Play.CollisionBox.t()
  def from(data)
end

defimpl Play.Collision, for: Tuple do
  def from({:delete, _} = tuple), do: tuple
end
