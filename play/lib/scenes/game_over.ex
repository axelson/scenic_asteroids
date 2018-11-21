defmodule Play.Scene.GameOver do
  @moduledoc """
  Shows the user their score and let's them press a button to restart
  """

  use Scenic.Scene
  import Scenic.Primitives
  alias Scenic.Graph

  @initial_graph Graph.build()
                 # Rectangle used for capturing input for the scene
                 |> rect({Play.Utils.screen_width(), Play.Utils.screen_height()})
                 |> text("",
                   id: :score,
                   t: {Play.Utils.screen_width() / 2, Play.Utils.screen_height() / 2},
                   fill: :white,
                   font: :roboto_mono,
                   text_align: :center
                 )

  defmodule State do
    @moduledoc false
    defstruct [:viewport]
  end

  @impl Scenic.Scene
  def init(score, scenic_opts) do
    state = %State{viewport: scenic_opts[:viewport]}

    show_score(score)

    {:ok, state}
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

  def handle_input(key, _, state) do
    # IO.inspect(key, label: "ignore key")
    {:noreply, state}
  end

  def handle_input(_, _, state), do: {:noreply, state}

  defp restart_game(%State{viewport: vp}) do
    Scenic.ViewPort.set_root(vp, {Play.Scene.Splash, Play.Scene.Asteroids})
  end

  defp show_score(score) do
    message = "Your score was: #{score}"

    @initial_graph
    |> Graph.modify(:score, &Scenic.Primitives.text(&1, message))
    |> push_graph()
  end
end
