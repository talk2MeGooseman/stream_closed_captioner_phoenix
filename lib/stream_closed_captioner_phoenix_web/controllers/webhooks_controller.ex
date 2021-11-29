defmodule StreamClosedCaptionerPhoenixWeb.WebhooksController do
  use StreamClosedCaptionerPhoenixWeb, :controller

  @spec create(Plug.Conn.t(), any) :: Plug.Conn.t()
  def create(
        %Plug.Conn{assigns: %{twitch_event_type: "notification"}} = conn,
        %{"subscription" => %{"type" => "stream.online"}} = params
      ) do
    # Handling notification events
    IO.puts("========== Stream Online =============")
    IO.inspect(params)

    resp(conn, 200, "")
  end

  def create(
        %Plug.Conn{assigns: %{twitch_event_type: "notification"}} = conn,
        %{"subscription" => %{"type" => "channel.update"}} = _params
      ) do
    IO.puts("========== Channel Updated =============")

    resp(conn, 200, "")
  end

  def create(
        %Plug.Conn{assigns: %{twitch_event_type: "webhook_callback_verification"}} = conn,
        %{"challenge" => challenge} = _params
      ) do
    IO.puts("========== Webhook Verification =============")
    resp(conn, 200, challenge)
  end

  def create(
        %Plug.Conn{assigns: %{twitch_event_type: "revocation"}} = conn,
        _params
      ) do
    IO.puts("========== Webhook Revocation =============")
    resp(conn, 200, "")
  end
end
