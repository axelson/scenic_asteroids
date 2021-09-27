defmodule Play.Scene.GameOver do
  @moduledoc """
  Shows the user their score and let's them press a button to restart
  """

  use Scenic.Scene
  import Scenic.Primitives
  import Play.Utils, only: [input_state: 1]
  alias Scenic.Graph

  @refresh_rate round(1_000 / 30)

  defmodule State do
    @moduledoc false
    defstruct [:viewport, :graph]
  end

  @impl Scenic.Scene
  def init(scene, player_scores, _scenic_opts) do
    graph = show_score(player_scores)

    state = %State{viewport: scene.viewport, graph: graph}
    schedule_refresh()

    scene =
      scene
      |> assign(:state, state)
      |> push_graph(graph)

    {:ok, scene}
  end

  @impl Scenic.Scene
  def handle_input({:cursor_button, {:btn_left, input_state(:press), _, _}}, _context, scene) do
    restart_game(scene.assigns.state)
    {:noreply, scene}
  end

  def handle_input({:key, {_key, input_state(:press), _}}, _context, scene) do
    restart_game(scene.assigns.state)
    {:noreply, scene}
  end

  def handle_input(_, _, scene), do: {:noreply, scene}

  @impl GenServer
  def handle_info(:refresh, scene) do
    schedule_refresh()
    scene = push_graph(scene, scene.assigns.state.graph)
    {:noreply, scene}
  end

  defp restart_game(%State{viewport: vp}) do
    Scenic.ViewPort.set_root(vp, Play.Scene.Splash, Play.Scene.Asteroids)
  end

  defp show_score(player_scores) do
    score_messages =
      player_scores
      |> Enum.sort_by(fn {_, score} -> score end, &>=/2)
      |> Enum.map(fn {username, score} -> "#{username} - #{score}" end)
      |> Enum.join("\n")

    message = "Final scores:\n" <> score_messages

    font_size = 40
    {:ok, {_type, fm}} = Scenic.Assets.Static.meta(:roboto_mono)
    ascent = FontMetrics.ascent(font_size, fm)
    fm_width = FontMetrics.width(message, font_size, fm)
    num_lines = String.split(message, "\n") |> length()

    x = Play.Utils.screen_width() / 2 - fm_width / 2
    y = Play.Utils.screen_height() / 2 - num_lines * ascent / 2

    initial_graph()
    |> Graph.modify(:score, &Scenic.Primitives.text(&1, message, t: {x, y}))
  end

  defp initial_graph do
    Graph.build()
    # Rectangle used for capturing input for the scene
    |> rect({Play.Utils.screen_width(), Play.Utils.screen_height()},
      input: [:cursor_button]
    )
    |> text("",
      id: :score,
      t: {Play.Utils.screen_width() / 2, Play.Utils.screen_height() / 2},
      fill: :white,
      font: :roboto_mono,
      text_align: :left
    )
    |> Launcher.HiddenHomeButton.add_to_graph([])
  end

  defp schedule_refresh do
    Process.send_after(self(), :refresh, @refresh_rate)
  end
end
