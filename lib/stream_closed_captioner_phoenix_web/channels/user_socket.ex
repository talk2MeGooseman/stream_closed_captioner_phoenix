defmodule StreamClosedCaptionerPhoenixWeb.UserSocket do
  use Phoenix.Socket

  alias StreamClosedCaptionerPhoenix.Accounts
  alias StreamClosedCaptionerPhoenix.Accounts.User

  ## Channels
  # channel "room:*", StreamClosedCaptionerPhoenixWeb.RoomChannel

  channel "captions:*", StreamClosedCaptionerPhoenixWeb.CaptionsChannel

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
  def connect(%{"token" => "users_sessions:" <> encoded_token}, socket, _connect_info) do
    token = Base.url_decode64!(encoded_token)

    case Accounts.get_user_by_session_token(token) do
      %User{} = user ->
        {:ok, assign(socket, :current_user, user)}

      _ ->
        :error
    end
  end

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
