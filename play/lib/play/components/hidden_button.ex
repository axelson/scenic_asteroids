defmodule Play.Components.HiddenButton do
  @moduledoc """
  An invisible button, for use as hot corners on Nerves
  """

  use Scenic.Component, has_children: false

  alias Scenic.Graph

  def init({width, height}, opts) when is_list(opts) do
    id = opts[:id]

    graph =
      Graph.build()
      |> Scenic.Primitives.rect({width, height}, opts)

    state = %{
      graph: graph,
      id: id
    }

    push_graph(graph)

    {:ok, state}
  end

  def verify(data) do
    IO.inspect(data, label: "data")
    {:ok, data}
  end

  def handle_input({:cursor_button, {:left, :press, _, _}}, _context, state) do
    %{id: id} = state
    send_event({:click, id})

    {:noreply, state}
  end

  def handle_input(_event, _context, state), do: {:noreply, state}
end
