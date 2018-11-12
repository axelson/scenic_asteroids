defprotocol Play.ScenicEntity do
  @type id :: String.t()
  @type entity_pending_destruction :: {:delete, id}

  @typedoc "Any entity that can be drawn onto the graph"
  @type entity :: any

  @spec id(any) :: id()
  def id(data)

  # TODO: Is tick part of ScenicEntity or GameEntity? Maybe it'll be separated later
  @doc "Advance a data structure forward one tick in time"
  @spec tick(any) :: any
  def tick(data)

  @doc "Draw the entity onto the Graph"
  @spec draw(any, Scenic.Graph.t()) :: Scenic.Graph.t()
  def draw(data, graph)
end

defimpl Play.ScenicEntity, for: Tuple do
  def id({:delete, id}), do: id

  def tick({:delete, _} = tuple), do: tuple

  def draw({:delete, _}, graph), do: graph
end
