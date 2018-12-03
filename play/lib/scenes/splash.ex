defmodule Play.Scene.Splash do
  @moduledoc """
  Sample splash scene.

  This scene demonstrate a very simple animation and transition to another scene.

  It also shows how to load a static texture and paint it into a rectangle.
  """

  use Scenic.Scene
  alias Scenic.Graph
  alias Scenic.ViewPort
  import Scenic.Primitives, only: [{:rect, 3}, {:update_opts, 2}]

  @logo_path :code.priv_dir(:play)
               |> Path.join("logo.png")

  @parrot_hash "UfHCVlANI2cFbwSpJey64FxjT-0"
  @logo_hash Scenic.Cache.Hash.file!(@logo_path, :sha)

  @logo_width 515
  @logo_height 181

  @graph Graph.build()
         |> rect(
           {@logo_width, @logo_height},
           id: :logo,
           fill: {:image, @logo_hash}
         )

  @animate_ms 10
  @finish_delay_ms 100

  # --------------------------------------------------------
  def init(first_scene, opts) do
    viewport = opts[:viewport]

    # calculate the transform that centers the logo in the viewport
    {:ok, %ViewPort.Status{size: {vp_width, vp_height}}} = ViewPort.info(viewport)

    move = {
      vp_width / 2 - @logo_width / 2,
      vp_height / 2 - @logo_height / 2
    }

    # load the logo texture into the cache
    {:ok, _hash} = Scenic.Cache.File.load(@logo_path, @logo_hash)

    # move the logo into the right location
    graph =
      Graph.modify(@graph, :logo, &update_opts(&1, translate: move))
      |> push_graph()

    # start a very simple animation timer
    {:ok, timer} = :timer.send_interval(@animate_ms, :animate)

    state = %{
      viewport: viewport,
      timer: timer,
      graph: graph,
      first_scene: first_scene,
      alpha: 0
    }

    push_graph(graph)

    {:ok, state}
  end

  # --------------------------------------------------------
  # A very simple animation. A timer runs, which increments a counter. The counter
  # Is applied as an alpha channel to the logo png.
  # When it is fully saturated, transition to the first real scene
  def handle_info(
        :animate,
        %{timer: timer, alpha: a} = state
      )
      when a >= 256 do
    :timer.cancel(timer)
    Process.send_after(self(), :finish, @finish_delay_ms)
    {:noreply, state}
  end

  def handle_info(:finish, state) do
    go_to_first_scene(state)
    {:noreply, state}
  end

  def handle_info(:animate, %{alpha: alpha, graph: graph} = state) do
    graph =
      graph
      |> Graph.modify(:logo, &update_opts(&1, fill: {:image, @logo_hash}))
      |> push_graph()

    {:noreply, %{state | graph: graph, alpha: alpha + 2}}
  end

  # --------------------------------------------------------
  # short cut to go right to the new scene on user input
  def handle_input({:cursor_button, {_, :press, _, _}}, _context, state) do
    go_to_first_scene(state)
    {:noreply, state}
  end

  def handle_input({:key, _}, _context, state) do
    go_to_first_scene(state)
    {:noreply, state}
  end

  def handle_input(_input, _context, state), do: {:noreply, state}

  # --------------------------------------------------------
  defp go_to_first_scene(%{viewport: vp, first_scene: first_scene}) do
    ViewPort.set_root(vp, {first_scene, nil})
  end
end
