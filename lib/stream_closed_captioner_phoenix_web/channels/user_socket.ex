defmodule StreamClosedCaptionerPhoenixWeb.UserSocket do
  use Phoenix.Socket
  use Absinthe.Phoenix.Socket, schema: StreamClosedCaptionerPhoenixWeb.Schema

  alias StreamClosedCaptionerPhoenix.Accounts

  ## Channels
  # channel "room:*", StreamClosedCaptionerPhoenixWeb.RoomChannel

  channel("captions:*", StreamClosedCaptionerPhoenixWeb.CaptionsChannel)
  channel("costream:*", StreamClosedCaptionerPhoenixWeb.CostreamChannel)

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
  @impl true
  def connect(%{"token" => token}, socket, _connect_info) do
    case Phoenix.Token.verify(socket, "user socket", token, max_age: 5_184_000) do
      {:ok, user_id} ->
        current_user = Accounts.get_user!(user_id)
        {:ok, assign(socket, :current_user, current_user)}

      {:error, _} ->
        :error
    end
  end

  # Co-streamer guest socket: authenticated purely by the signed guest link
  # token (no user account). Grants access to the host's costream channel
  # only — CaptionsChannel requires :current_user, which is never assigned
  # here.
  def connect(%{"costreamToken" => token}, socket, _connect_info) do
    case StreamClosedCaptionerPhoenix.Costream.verify_guest_token(token) do
      {:ok, guest} ->
        {:ok, assign(socket, :costream_guest, guest)}

      {:error, _} ->
        :error
    end
  end

  def connect(%{"Authorization" => "Bearer " <> token} = _params, socket, _connect_info) do
    case Twitch.Jwt.verify_and_validate(token) do
      {:ok, _} ->
        socket = Absinthe.Phoenix.Socket.put_options(socket, context: %{})
        {:ok, socket}

      {:error, _} ->
        :error
    end
  end

  def connect(_params, _socket, _connect_info), do: :error

  # Socket id's are topics that allow you to identify all sockets for a given user:
  #
  #     def id(socket), do: "user_socket:#{socket.assigns.user_id}"
  #
  # Would allow you to broadcast a "disconnect" event and terminate
  # all active sockets and channels for a given user:
  #
  #     StreamClosedCaptionerPhoenixWeb.Endpoint.broadcast("user_socket:#{user.id}", "disconnect", %{})
  #
  # Returning `nil` makes this socket anonymous.
  @impl true
  def id(_socket), do: nil
end
