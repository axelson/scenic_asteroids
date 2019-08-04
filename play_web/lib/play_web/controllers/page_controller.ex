defmodule PlayWeb.PageController do
  use PlayWeb, :controller

  @user_salt "user sel"

  plug :require_user when action not in [:signin]

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def signin(conn, %{"user" => %{"username" => username}}) do
    conn
    |> put_session(:username, username)
    |> redirect(to: "/")
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
end
