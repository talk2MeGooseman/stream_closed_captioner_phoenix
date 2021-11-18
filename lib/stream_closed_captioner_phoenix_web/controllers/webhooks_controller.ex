defmodule StreamClosedCaptionerPhoenixWeb.WebhooksController do
  use StreamClosedCaptionerPhoenixWeb, :controller

  @spec create(Plug.Conn.t(), any) :: Plug.Conn.t()
  def create(
        %Plug.Conn{assigns: %{twitch_event_type: "notification"}} = conn,
        %{subscription: %{type: "stream.online"}} = params
      ) do
    # Handling notification events
    IO.inspect(params)

    put_status(conn, 204)
  end

  def create(
        %Plug.Conn{assigns: %{twitch_event_type: "webhook_callback_verification"}} = conn,
        %{"challenge" => challenge} = _params
      ) do
    resp(conn, 200, challenge)
  end

  def create(
        %Plug.Conn{assigns: %{twitch_event_type: "revocation"}} = conn,
        _params
      ) do
    resp(conn, 200, "")
  end
end
