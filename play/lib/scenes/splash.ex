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

  @logo_hash Scenic.Cache.Hash.file!(@logo_path, :sha)

  @logo_width 515
  @logo_height 181
  @initial_y_coord 0

  @graph Graph.build()
         |> rect(
           {@logo_width, @logo_height},
           id: :logo,
           fill: {:image, @logo_hash}
         )

  @animate_ms 10
  @finish_delay_ms 750

  defmodule State do
    @moduledoc false
    defstruct [
      :viewport,
      :timer,
      :graph,
      :first_scene,
      :counter,
      :final_x_coord,
      :final_y_coord
    ]
  end

  # --------------------------------------------------------
  def init(first_scene, opts) do
    viewport = opts[:viewport]

    # calculate the transform that centers the logo in the viewport
    {:ok, %ViewPort.Status{size: {vp_width, vp_height}}} = ViewPort.info(viewport)

    final_y_coord = vp_height / 2 - @logo_height / 2
    final_x_coord = vp_width / 2 - @logo_width / 2

    move = {
      final_x_coord,
      @initial_y_coord
    }

    # load the logo texture into the cache
    {:ok, _hash} = Scenic.Cache.File.load(@logo_path, @logo_hash)

    # move the logo into the right location
    graph =
      Graph.modify(@graph, :logo, &update_opts(&1, translate: move))
      |> push_graph()

    # start a very simple animation timer
    {:ok, timer} = :timer.send_interval(@animate_ms, :animate)

    state = %State{
      viewport: viewport,
      timer: timer,
      graph: graph,
      first_scene: first_scene,
      counter: 0,
      final_x_coord: final_x_coord,
      final_y_coord: final_y_coord
    }

    # Why am I pushing this twice?
    push_graph(graph)

    {:ok, state}
  end

  # --------------------------------------------------------
  # A very simple animation. A timer runs, which increments a counter. The counter
  # is used to move the logo into the center of the screen
  # Then there is a short pause and the next scene is loaded
  def handle_info(
        :animate,
        %{timer: timer, counter: counter} = state
      )
      when counter >= 256 do
    :timer.cancel(timer)
    Process.send_after(self(), :finish, @finish_delay_ms)
    {:noreply, state}
  end

  def handle_info(:finish, state) do
    go_to_first_scene(state)
    {:noreply, state}
  end

  def handle_info(:animate, %State{} = state) do
    %State{graph: graph, counter: counter, final_x_coord: final_x_coord, final_y_coord: final_y_coord} = state
    y_coord = counter / 255 * final_y_coord
    t = {final_x_coord, y_coord}

    graph =
      graph
      |> Graph.modify(:logo, &update_opts(&1, fill: {:image, @logo_hash}, translate: t))
      |> push_graph()

    {:noreply, %State{state | graph: graph, counter: counter + 1}}
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
