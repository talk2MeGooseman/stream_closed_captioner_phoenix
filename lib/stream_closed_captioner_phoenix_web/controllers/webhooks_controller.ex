defmodule StreamClosedCaptionerPhoenixWeb.WebhooksController do
  use StreamClosedCaptionerPhoenixWeb, :controller

  @spec create(Plug.Conn.t(), any) :: Plug.Conn.t()
  def create(
        %Plug.Conn{assigns: %{twitch_event_type: "notification"}} = conn,
        %{
          "subscription" => %{"type" => "stream.online"},
          "event" => event
        }
      ) do
    IO.puts("========== Stream Online =============")

    StreamClosedCaptionerPhoenix.Jobs.JoinChat.new(event)
    |> Oban.insert()

    resp(conn, 200, "")
  end

  def create(
        %Plug.Conn{assigns: %{twitch_event_type: "notification"}} = conn,
        %{
          "subscription" => %{"type" => type},
          "event" => event
        }
      ) do
    IO.puts("========== Webhook Event: #{type} =============")
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
