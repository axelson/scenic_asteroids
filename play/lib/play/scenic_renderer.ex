defmodule Play.ScenicRenderer do
  @moduledoc """
  Oversee the rendering of entities on a graph
  """

  alias Play.ScenicEntity
  alias Scenic.Graph

  @spec draw(ScenicEntity.entity(), Scenic.Graph.t()) :: Scenic.Graph.t()
  def draw({:delete, id}, graph) do
    Graph.delete(graph, id)
  end

  def draw(entity, graph) do
    id = ScenicEntity.id(entity)
    case Graph.get(graph, id) do
      [] ->
        ScenicEntity.draw(entity, graph)

      [_] ->
        Graph.modify(graph, id, fn graph ->
          ScenicEntity.draw(entity, graph)
        end)
    end
  end
end
