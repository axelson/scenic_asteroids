defprotocol Play.Tick do
  @doc "Advance a data structure forward one tick in tim"
  def tick(data)
end

defimpl Play.Tick, for: Tuple do
  def tick({:delete, _} = tuple), do: tuple
end
