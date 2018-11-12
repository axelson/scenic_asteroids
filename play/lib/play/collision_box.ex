defmodule Play.CollisionBox do
  @moduledoc """
  Shows the collision box of an entity. Used to assist in finding collisions and
  can be shown for debug purposes.
  """

  defstruct [:id, :entity_id, :t, :size]

  @type t :: %__MODULE__{
          id: Play.ScenicEntity.id(),
          entity_id: Play.ScenicEntity.id(),
          t: Play.Scene.Asteroids.coords(),
          size: integer
        }

  def id(entity_id), do: entity_id <> "_collision_box"

  defimpl Play.ScenicEntity, for: __MODULE__ do
    alias Play.CollisionBox

    def id(%CollisionBox{id: id}), do: id

    # Should this be implemented?
    def tick(%CollisionBox{} = box), do: box

    def draw(%CollisionBox{} = box, graph) do
      %{id: id, size: size, t: t} = box
      Scenic.Primitives.rectangle(graph, {size, size}, id: id, t: t, stroke: {1, :white})
    end
  end
end

defprotocol Play.Collision do
  @doc "Convert this data structure into a collision box"
  @spec from(any) :: Play.CollisionBox.t() | Play.ScenicEntity.entity_pending_destruction()
  def from(data)
end

defimpl Play.Collision, for: Tuple do
  def from({:delete, id}), do: {:delete, Play.CollisionBox.id(id)}
end
