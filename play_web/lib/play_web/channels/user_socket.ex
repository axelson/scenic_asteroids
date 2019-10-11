defmodule PlayWeb.UserSocket do
  use Phoenix.Socket

  require Logger

  ## Channels
  channel "lobby", PlayWeb.LobbyChannel
  channel "play", PlayWeb.PlayChannel

  @salt "user sel"

  # Socket params are passed from the client and can
  # be used to verify and authenticate a user. After
  # verification, you can put default assigns into
  # the socket that will be set for all channels, ie
  #
  #     {:ok, assign(socket, :user_id, verified_user_id)}
  #
  # To deny connection, return `:error`.
  #
  # See `Phoenix.Token` documentation for examples in
  # performing token verification on connect.
  def connect(params, socket, connect_info) do
    # Example connect_info:
    # %{peer_data: %{address: {192, 168, 1, 102}, port: 39127, ssl_cert: nil}, x_headers: []}

    ip_addr_tuple = connect_info.peer_data.address
    IO.inspect(socket, label: "socket")
    IO.inspect(connect_info, label: "connect_info")

    token = params["token"]

    with {:banned, false} <- {:banned, PlayWeb.BannedIPs.banned?()},
         {:ok, username} <- Phoenix.Token.verify(socket, @salt, token, max_age: 86400) do
      socket =
        socket
        |> assign(:username, username)
    else
      {:banned, true} ->
        socket_error(socket, :banned)

      {:error, :missing} ->
        socket_error(socket, :not_logged_in)
    end

    case Phoenix.Token.verify(socket, @salt, token, max_age: 86400) do
      {:ok, username} ->
        socket =
          socket
          |> assign(:username, username)

        {:ok, socket}

      {:error, :missing} ->
        socket_error(socket, :not_logged_in)

      err ->
        Logger.warn("An unhandled error occurred joining UserSocket: #{inspect(err)}")
        socket_error(socket, :unknown_error)
    end
  end

  # NOTE: We allow the user to join the socket but not any channels. This means
  # that in each channel we need to check that the user is logged in
  #
  # We need to do this because if we reject the socket completely we can't
  # return a descriptive error to the user
  defp socket_error(socket, error) do
    socket =
      socket
      |> assign(:error, error)

    {:ok, socket}
  end

  @doc """
  Get the logged in username or return a descriptive error. Meant to be called
  by each individual channel that wants to check if the user is logged in.
  """
  def logged_in_username(socket) do
    case socket.assigns do
      %{username: username} -> {:ok, username}
      %{error: error} -> {:error, error}
    end
  end

  # Socket id's are topics that allow you to identify all sockets for a given user:
  #
  #     def id(socket), do: "user_socket:#{socket.assigns.user_id}"
  #
  # Would allow you to broadcast a "disconnect" event and terminate
  # all active sockets and channels for a given user:
  #
  #     PlayWeb.Endpoint.broadcast("user_socket:#{user.id}", "disconnect", %{})
  #
  # Returning `nil` makes this socket anonymous.
  def id(_socket), do: nil
end
