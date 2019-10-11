defmodule PlayWeb.PageController do
  use PlayWeb, :controller

  @user_salt "user sel"

  plug :require_user when action not in [:signin]

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def play(conn, _params) do
    render(conn, "play.html")
  end

  def signin(conn, %{"user" => %{"username" => username}}) do
    case check_valid_username(username) do
      :ok ->
        conn
        |> put_session(:username, username)
        |> redirect(to: "/play")

      {:error, message} ->
        conn
        |> put_flash(:error, message)
        |> render("signin.html")
    end
  end

  def logout(conn, _) do
    conn
    |> put_flash(:info, "Logged out!")
    |> clear_session()
    |> redirect(to: "/")
  end

  def require_user(conn, _) do
    if username = get_session(conn, :username) do
      conn
      |> assign(:username, username)
      |> assign(:user_token, Phoenix.Token.sign(conn, @user_salt, username))
    else
      conn
      |> put_flash(:error, "Please sign-in!")
      |> render("signin.html")
      |> halt()
    end
  end

  defp check_valid_username("console"), do: {:error, "That username is reserved"}

  defp check_valid_username(username) do
    length = String.length(username)

    if length <= 8 do
      :ok
    else
      {:error, "A username can be at most 8 characters, got #{length}"}
    end
  end
end
