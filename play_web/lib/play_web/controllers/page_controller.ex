defmodule PlayWeb.PageController do
  use PlayWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
