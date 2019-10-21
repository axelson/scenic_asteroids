defmodule Play.Scene.Splash do
  @moduledoc """
  Sample splash scene.

  This scene demonstrate a very simple animation and transition to another scene.

  It also shows how to load a static texture and paint it into a rectangle.
  """

  use Scenic.Scene
  alias Scenic.Graph
  alias Scenic.ViewPort
  import Scenic.Primitives, only: [{:rect, 3}, {:rect, 2}, {:update_opts, 2}]

  @counter_max 500

  # Heights of the logo slices
  @logo_filenames [
    {"logo-0.png", height: 4, start_t: 0},
    {"logo-1.png", height: 6, start_t: 50},
    {"logo-2.png", height: 5, start_t: 100},
    {"logo-3.png", height: 6, start_t: 150},
    {"logo-4.png", height: 5, start_t: 190},
    {"logo-5.png", height: 4, start_t: 230},
    {"logo-6.png", height: 13, start_t: 250}
  ]

  @logo_hashes Map.new(
                 @logo_filenames,
                 fn {filename, _} ->
                   hash =
                     Scenic.Cache.Support.Hash.file!(
                       Path.join(:code.priv_dir(:play), filename),
                       :sha
                     )

                   {filename, hash}
                 end
               )

  @logo_width 344

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
  def init(first_scene, opts) do
    viewport = opts[:viewport]

    # calculate the transform that centers the logo in the viewport
    {:ok, %ViewPort.Status{size: {vp_width, vp_height}}} = ViewPort.info(viewport)

    final_y_coord = vp_height / 2
    final_x_coord = vp_width / 2 - @logo_width / 2

    load_hashes()

    graph =
      Graph.build()
      # Rectangle used for capturing input for the scene
      |> rect({vp_width, vp_height})
      |> render_logo_rects()
      |> Launcher.HiddenHomeButton.add_to_graph([])

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

    {:ok, state, push: graph}
  end

  def render_logo_rects(graph) do
    Enum.reduce(@logo_filenames, graph, fn {filename, opts}, graph ->
      graph
      |> rect(
        {@logo_width, opts[:height]},
        id: filename,
        fill: image(filename),
        # Start off the screen
        t: {0, -20}
      )
    end)
  end

  def handle_info(
        :animate,
        %{timer: timer, counter: counter} = state
      )
      when counter > @counter_max do
    :timer.cancel(timer)
    Process.send_after(self(), :finish, @finish_delay_ms)
    {:noreply, state}
  end

  def handle_info(:finish, state) do
    go_to_first_scene(state)
    {:noreply, state}
  end

  def handle_info(:animate, %State{} = state) do
    %State{
      graph: graph,
      counter: counter,
      final_x_coord: final_x_coord,
      final_y_coord: final_y_coord
    } = state

    load_hashes()

    graph =
      @logo_filenames
      |> Enum.reduce(graph, fn {filename, opts}, graph ->
        start_time = Keyword.get(opts, :start_t)
        height = Keyword.get(opts, :height)

        if counter >= start_time && counter - start_time <= 70 do
          extra_y = total_height(filename)

          y = :math.pow(1.1, counter - start_time) - height - 2
          y_max = final_y_coord - extra_y
          t = {final_x_coord, min(y, y_max)}

          graph
          |> Graph.modify(filename, &update_opts(&1, file: image(filename), translate: t))
        else
          graph
        end
      end)

    {:noreply, %State{state | graph: graph, counter: counter + 1}, push: graph}
  end

  # Calculate the relative height of this slice of the logo
  defp total_height(filename) do
    Enum.reduce_while(@logo_filenames, 0, fn
      {^filename, opts}, height -> {:halt, height + opts[:height]}
      {_filename, opts}, height -> {:cont, height + opts[:height]}
    end)
  end

  defp load_hashes do
    @logo_filenames
    |> Enum.map(fn {filename, _} -> filename end)
    |> Enum.each(fn filename ->
      logo_path = :code.priv_dir(:play) |> Path.join(filename)
      {:ok, _hash} = Scenic.Cache.Static.Texture.load(logo_path, @logo_hashes[filename])
    end)
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

  defp image(filename), do: {:image, @logo_hashes[filename]}
end
