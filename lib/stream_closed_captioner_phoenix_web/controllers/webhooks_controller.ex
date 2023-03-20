defmodule StreamClosedCaptionerPhoenixWeb.WebhooksController do
  use StreamClosedCaptionerPhoenixWeb, :controller

  alias StreamClosedCaptionerPhoenix.Accounts
  alias StreamClosedCaptionerPhoenix.Accounts.EventsubSubscription
  alias StreamClosedCaptionerPhoenix.Accounts.User
  alias StreamClosedCaptionerPhoenix.Jobs.SendChatReminder
  alias StreamClosedCaptionerPhoenix.Settings
  alias StreamClosedCaptionerPhoenix.Settings.StreamSettings

  def create(
        %Plug.Conn{assigns: %{twitch_event_type: "notification"}} = conn,
        %{
          "subscription" => %{"type" => "stream.online", "id" => id},
          "event" => event
        }
      ) do
    with %User{} = user <-
           Accounts.get_user_by_provider_uid(Map.get(event, "broadcaster_user_id")),
         %EventsubSubscription{type: "stream.online"} <-
           Accounts.eventsub_subscription_id(id),
         %StreamSettings{} = stream_settings <-
           Settings.get_stream_settings_by_user_id!(user.id),
         {:reminder, true} <- {:reminder, stream_settings.turn_on_reminder} do
      if FunWithFlags.enabled?(:chat_reminder, for: user) do
        dbg("Sending chat reminder to #{user.username}")

        SendChatReminder.new(event, schedule_in: 300)
        |> Oban.insert()
      end
    else
      {:reminder, false} ->
        Twitch.delete_event_subscription(id)

      _ ->
        :ok
    end

    resp(conn, 200, "")
  end

  def create(
        %Plug.Conn{assigns: %{twitch_event_type: "notification"}} = conn,
        %{
          "subscription" => %{"type" => "stream.offline", "id" => id},
          "event" => event
        }
      ) do
    with %User{} = user <-
           Accounts.get_user_by_provider_uid(Map.get(event, "broadcaster_user_id")),
         %EventsubSubscription{type: "stream.offline"} <-
           Accounts.eventsub_subscription_id(id),
         %StreamSettings{} = stream_settings <-
           Settings.get_stream_settings_by_user_id!(user.id),
         {:auto_off, true} <- {:auto_off, stream_settings.auto_off_captions} do
      StreamClosedCaptionerPhoenixWeb.Endpoint.broadcast(
        "captions:#{user.id}",
        "stream.offline",
        %{}
      )
    else
      {:reminder, false} ->
        Twitch.delete_event_subscription(id)

      _ ->
        dbg("Ignoring stream.offline")
        :ok
    end

    resp(conn, 200, "")
  end

  def create(
        %Plug.Conn{assigns: %{twitch_event_type: "notification"}} = conn,
        %{
          "subscription" => %{"type" => _type},
          "event" => _event
        }
      ) do
    resp(conn, 200, "")
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
