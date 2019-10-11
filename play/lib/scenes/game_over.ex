defmodule Play.Scene.GameOver do
  @moduledoc """
  Shows the user their score and let's them press a button to restart
  """

  use Scenic.Scene
  import Scenic.Primitives
  alias Scenic.Graph

  @refresh_rate round(1_000 / 30)

  @initial_graph Graph.build()
                 # Rectangle used for capturing input for the scene
                 |> rect({Play.Utils.screen_width(), Play.Utils.screen_height()})
                 |> text("",
                   id: :score,
                   t: {Play.Utils.screen_width() / 2, Play.Utils.screen_height() / 2},
                   fill: :white,
                   font: :roboto_mono,
                   text_align: :left
                 )
                 |> Launcher.HiddenHomeButton.add_to_graph([])

  defmodule State do
    @moduledoc false
    defstruct [:viewport, :graph]
  end

  @impl Scenic.Scene
  def init(player_scores, scenic_opts) do
    graph = show_score(player_scores)

    state = %State{viewport: scenic_opts[:viewport], graph: graph}
    schedule_refresh()

    {:ok, state, push: graph}
  end

  @impl Scenic.Scene
  def handle_input({:cursor_button, {_, :press, _, _}}, _context, state) do
    restart_game(state)
    {:noreply, state}
  end

  def handle_input({:key, {key, _, _}}, _context, state) do
    case String.to_charlist(key) do
      [char] when char in ?A..?Z or key in [" "] ->
        restart_game(state)

      _ ->
        nil
    end

    {:noreply, state}
  end

  def handle_input(_, _, state), do: {:noreply, state}

  @impl Scenic.Scene
  def handle_info(:refresh, state) do
    schedule_refresh()
    {:noreply, state, push: state.graph}
  end

  defp restart_game(%State{viewport: vp}) do
    Scenic.ViewPort.set_root(vp, {Play.Scene.Splash, Play.Scene.Asteroids})
  end

  defp show_score(player_scores) do
    score_messages =
      player_scores
      |> Enum.sort_by(fn {_, score} -> score end, &>=/2)
      |> Enum.map(fn {username, score} -> "#{username} - #{score}" end)
      |> Enum.join("\n")

    message = "Final scores:\n" <> score_messages

    font_size = 40
    font = :roboto
    fm = Scenic.Cache.Static.FontMetrics.get!(font)
    ascent = FontMetrics.ascent(font_size, fm)
    fm_width = FontMetrics.width(message, font_size, fm)
    num_lines = String.split(message, "\n") |> length()

    x = Play.Utils.screen_width() / 2 - fm_width / 2
    y = Play.Utils.screen_height() / 2 - num_lines * ascent / 2

    @initial_graph
    |> Graph.modify(:score, &Scenic.Primitives.text(&1, message, t: {x, y}))
  end

  defp schedule_refresh do
    Process.send_after(self(), :refresh, @refresh_rate)
  end
end
