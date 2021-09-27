defmodule Play.Scene.Splash do
  @moduledoc """
  Sample splash scene.

  This scene demonstrate a very simple animation and transition to another scene.

  It also shows how to load a static texture and paint it into a rectangle.
  """

  use Scenic.Scene
  require Play.Utils
  import Scenic.Primitives, only: [{:rect, 3}, {:update_opts, 2}]
  alias Scenic.Graph
  alias Scenic.ViewPort

  @logo_width 515
  @logo_height 211
  @initial_y_coord 0

  @animate_ms 10
  @finish_delay_ms 9750

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
  def init(scene, first_scene, _scenic_opts) do
    Scenic.Scene.capture_input(scene, [:key])
    # Scenic.ViewPort.capture_input(scene, )
    # calculate the transform that centers the logo in the viewport
    %Scenic.ViewPort{size: {vp_width, vp_height}} = scene.viewport

    final_y_coord = vp_height / 2 - @logo_height / 2
    final_x_coord = vp_width / 2 - @logo_width / 2

    move = {
      final_x_coord,
      @initial_y_coord
    }

    graph =
      Graph.build()
      # Rectangle used for capturing input for the scene
      |> rect({vp_width, vp_height}, input: [:cursor_button])
      |> rect(
        {@logo_width, @logo_height},
        id: :logo,
        fill: image()
      )
      |> Launcher.HiddenHomeButton.add_to_graph([])

    # move the logo into the right location
    graph = Graph.modify(graph, :logo, &update_opts(&1, translate: move))

    # start a very simple animation timer
    {:ok, timer} = :timer.send_interval(@animate_ms, :animate)

    state = %State{
      viewport: scene.viewport,
      timer: timer,
      graph: graph,
      first_scene: first_scene,
      counter: 0,
      final_x_coord: final_x_coord,
      final_y_coord: final_y_coord
    }

    scene =
      scene
      |> assign(:state, state)
      |> push_graph(graph)

    {:ok, scene}
  end

  # --------------------------------------------------------
  # A very simple animation. A timer runs, which increments a counter. The counter
  # is used to move the logo into the center of the screen
  # Then there is a short pause and the next scene is loaded
  def handle_info(
        :animate,
        %{assigns: %{state: %{timer: timer, counter: counter}}} = scene
      )
      when counter >= 256 do
    :timer.cancel(timer)
    Process.send_after(self(), :finish, @finish_delay_ms)
    {:noreply, scene}
  end

  def handle_info(:finish, scene) do
    go_to_first_scene(scene.assigns.state)
    {:noreply, scene}
  end

  def handle_info(:animate, scene) do
    state = scene.assigns.state

    %State{
      graph: graph,
      counter: counter,
      final_x_coord: final_x_coord,
      final_y_coord: final_y_coord
    } = state

    y_coord = counter / 255 * final_y_coord
    t = {final_x_coord, y_coord}

    graph =
      graph
      |> Graph.modify(:logo, &update_opts(&1, fill: image(), translate: t))

    state = %State{state | graph: graph, counter: counter + 1}

    scene =
      scene
      |> assign(:state, state)
      |> push_graph(graph)

    {:noreply, scene}
  end

  # --------------------------------------------------------
  # short cut to go right to the new scene on user input
  def handle_input({:cursor_button, {_, 1, _, _}}, _context, scene) do
    go_to_first_scene(scene.assigns.state)
    {:noreply, scene}
  end

  def handle_input({:key, _key}, _context, scene) do
    go_to_first_scene(scene.assigns.state)
    {:noreply, scene}
  end

  def handle_input(_input, _context, scene), do: {:noreply, scene}

  # --------------------------------------------------------
  defp go_to_first_scene(%{viewport: vp, first_scene: first_scene}) do
    ViewPort.set_root(vp, first_scene, nil)
  end

  defp image, do: {:image, {:play, "images/logo.png"}}
end
