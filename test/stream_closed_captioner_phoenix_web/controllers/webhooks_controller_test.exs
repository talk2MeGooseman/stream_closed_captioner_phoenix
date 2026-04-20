defmodule StreamClosedCaptionerPhoenixWeb.WebhooksControllerTest do
  use StreamClosedCaptionerPhoenixWeb.ConnCase, async: false
  use Oban.Testing, repo: StreamClosedCaptionerPhoenix.Repo

  import Mox

  alias StreamClosedCaptionerPhoenix.Accounts
  alias StreamClosedCaptionerPhoenix.Jobs.SendChatReminder
  alias StreamClosedCaptionerPhoenix.Repo
  alias StreamClosedCaptionerPhoenix.Settings.StreamSettings

  setup :verify_on_exit!

  setup_all do
    System.put_env("TWITCH_EVENTSUB_SECRET", "test-secret")
    on_exit(fn -> System.delete_env("TWITCH_EVENTSUB_SECRET") end)
    :ok
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  # Builds a signed webhook conn without dispatching.
  # Sets raw_body assign + the four required Twitch headers.
  defp signed_webhook_conn(conn, event_type, body_json) do
    msg_id = "test-msg-id-#{System.unique_integer([:positive])}"
    timestamp = DateTime.utc_now() |> DateTime.to_iso8601()
    secret = "test-secret"

    signature =
      "sha256=" <>
        Base.encode16(
          :crypto.mac(:hmac, :sha256, secret, msg_id <> timestamp <> body_json),
          case: :lower
        )

    conn
    |> Plug.Conn.assign(:raw_body, body_json)
    |> put_req_header("content-type", "application/json")
    |> put_req_header("twitch-eventsub-message-id", msg_id)
    |> put_req_header("twitch-eventsub-message-timestamp", timestamp)
    |> put_req_header("twitch-eventsub-message-signature", signature)
    |> put_req_header("twitch-eventsub-message-type", event_type)
  end

  # Dispatches a signed POST to /webhooks.
  defp post_signed(base_conn, event_type, params) do
    body_json = Jason.encode!(params)
    signed = signed_webhook_conn(base_conn, event_type, body_json)
    post(signed, Routes.webhooks_path(signed, :create), body_json)
  end

  # ---------------------------------------------------------------------------
  # HTTPSignature plug
  # ---------------------------------------------------------------------------

  describe "HTTPSignature plug" do
    test "rejects request with invalid signature", %{conn: conn} do
      body_json = Jason.encode!(%{"challenge" => "abc"})
      bad_sig = "sha256=0000000000000000000000000000000000000000000000000000000000000000"

      conn =
        conn
        |> Plug.Conn.assign(:raw_body, body_json)
        |> put_req_header("content-type", "application/json")
        |> put_req_header("twitch-eventsub-message-id", "msg-id")
        |> put_req_header("twitch-eventsub-message-timestamp", "2024-01-01T00:00:00Z")
        |> put_req_header("twitch-eventsub-message-signature", bad_sig)
        |> put_req_header("twitch-eventsub-message-type", "webhook_callback_verification")

      conn = post(conn, Routes.webhooks_path(conn, :create), body_json)
      assert conn.status == 400
    end

    test "rejects request with missing signature headers", %{conn: conn} do
      body_json = Jason.encode!(%{"challenge" => "abc"})

      conn =
        conn
        |> Plug.Conn.assign(:raw_body, body_json)
        |> put_req_header("content-type", "application/json")

      # No Twitch headers → plug halts with 400
      conn = post(conn, Routes.webhooks_path(conn, :create), body_json)
      assert conn.status == 400
    end

    test "rejects request when raw_body assign is missing", %{conn: conn} do
      body_json = Jason.encode!(%{"challenge" => "abc"})

      # No raw_body assign means plug cannot verify → halts with 400
      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> put_req_header("twitch-eventsub-message-id", "msg-id")
        |> put_req_header("twitch-eventsub-message-timestamp", "2024-01-01T00:00:00Z")
        |> put_req_header("twitch-eventsub-message-signature", "sha256=anything")
        |> put_req_header("twitch-eventsub-message-type", "webhook_callback_verification")

      conn = post(conn, Routes.webhooks_path(conn, :create), body_json)
      assert conn.status == 400
    end
  end

  # ---------------------------------------------------------------------------
  # webhook_callback_verification
  # ---------------------------------------------------------------------------

  describe "webhook_callback_verification" do
    test "echoes the challenge in the response", %{conn: conn} do
      params = %{"challenge" => "test-challenge-xyz"}
      conn = post_signed(conn, "webhook_callback_verification", params)

      assert conn.status == 200
      assert conn.resp_body == "test-challenge-xyz"
    end
  end

  # ---------------------------------------------------------------------------
  # revocation
  # ---------------------------------------------------------------------------

  describe "revocation" do
    test "returns 200", %{conn: conn} do
      params = %{
        "subscription" => %{"type" => "stream.online", "id" => "sub-id-123"},
        "event" => %{}
      }

      conn = post_signed(conn, "revocation", params)
      assert conn.status == 200
    end
  end

  # ---------------------------------------------------------------------------
  # catch-all notification (unknown subscription type)
  # ---------------------------------------------------------------------------

  describe "notification (unknown type)" do
    test "returns 200 for unrecognized event types", %{conn: conn} do
      params = %{
        "subscription" => %{"type" => "channel.follow", "id" => "sub-id-456"},
        "event" => %{"broadcaster_user_id" => "99999"}
      }

      conn = post_signed(conn, "notification", params)
      assert conn.status == 200
    end
  end

  # ---------------------------------------------------------------------------
  # stream.online
  # ---------------------------------------------------------------------------

  describe "stream.online notification" do
    setup do
      user = insert(:user)
      broadcaster_uid = user.uid

      {:ok, sub} =
        Accounts.create_eventsub_subscription(user, %{
          type: "stream.online",
          subscription_id: "eventsub-online-#{System.unique_integer([:positive])}"
        })

      {:ok, user: user, sub: sub, broadcaster_uid: broadcaster_uid}
    end

    test "enqueues SendChatReminder when turn_on_reminder is true and flag enabled", %{
      conn: conn,
      user: user,
      sub: sub,
      broadcaster_uid: broadcaster_uid
    } do
      Repo.update!(StreamSettings.changeset(user.stream_settings, %{turn_on_reminder: true}))
      FunWithFlags.enable(:chat_reminder, for_actor: user)

      params = %{
        "subscription" => %{"type" => "stream.online", "id" => sub.subscription_id},
        "event" => %{"broadcaster_user_id" => broadcaster_uid}
      }

      conn = post_signed(conn, "notification", params)

      assert conn.status == 200
      assert_enqueued(worker: SendChatReminder)
    end

    test "does not enqueue job when turn_on_reminder is true but flag is disabled", %{
      conn: conn,
      user: user,
      sub: sub,
      broadcaster_uid: broadcaster_uid
    } do
      Repo.update!(StreamSettings.changeset(user.stream_settings, %{turn_on_reminder: true}))
      # Do not enable :chat_reminder flag

      params = %{
        "subscription" => %{"type" => "stream.online", "id" => sub.subscription_id},
        "event" => %{"broadcaster_user_id" => broadcaster_uid}
      }

      conn = post_signed(conn, "notification", params)

      assert conn.status == 200
      refute_enqueued(worker: SendChatReminder)
    end

    test "returns 200 when broadcaster user is not found", %{conn: conn, sub: sub} do
      params = %{
        "subscription" => %{"type" => "stream.online", "id" => sub.subscription_id},
        "event" => %{"broadcaster_user_id" => "nonexistent-uid"}
      }

      conn = post_signed(conn, "notification", params)
      assert conn.status == 200
    end

    test "returns 200 when no matching eventsub subscription exists", %{
      conn: conn,
      broadcaster_uid: broadcaster_uid
    } do
      params = %{
        "subscription" => %{"type" => "stream.online", "id" => "no-such-sub-id"},
        "event" => %{"broadcaster_user_id" => broadcaster_uid}
      }

      conn = post_signed(conn, "notification", params)
      assert conn.status == 200
    end
  end

  # ---------------------------------------------------------------------------
  # stream.offline
  # ---------------------------------------------------------------------------

  describe "stream.offline notification" do
    setup do
      user = insert(:user)
      broadcaster_uid = user.uid

      {:ok, sub} =
        Accounts.create_eventsub_subscription(user, %{
          type: "stream.offline",
          subscription_id: "eventsub-offline-#{System.unique_integer([:positive])}"
        })

      {:ok, user: user, sub: sub, broadcaster_uid: broadcaster_uid}
    end

    test "broadcasts stream.offline on captions topic when auto_off_captions is true", %{
      conn: conn,
      user: user,
      sub: sub,
      broadcaster_uid: broadcaster_uid
    } do
      Repo.update!(StreamSettings.changeset(user.stream_settings, %{auto_off_captions: true}))
      StreamClosedCaptionerPhoenixWeb.Endpoint.subscribe("captions:#{user.id}")

      params = %{
        "subscription" => %{"type" => "stream.offline", "id" => sub.subscription_id},
        "event" => %{"broadcaster_user_id" => broadcaster_uid}
      }

      conn = post_signed(conn, "notification", params)

      assert conn.status == 200
      assert_receive %Phoenix.Socket.Broadcast{topic: "captions:" <> _, event: "stream.offline"}
    end

    test "does not broadcast when auto_off_captions is false", %{
      conn: conn,
      user: user,
      sub: sub,
      broadcaster_uid: broadcaster_uid
    } do
      # auto_off_captions defaults to false; no update needed
      StreamClosedCaptionerPhoenixWeb.Endpoint.subscribe("captions:#{user.id}")

      params = %{
        "subscription" => %{"type" => "stream.offline", "id" => sub.subscription_id},
        "event" => %{"broadcaster_user_id" => broadcaster_uid}
      }

      conn = post_signed(conn, "notification", params)

      assert conn.status == 200
      refute_receive %Phoenix.Socket.Broadcast{topic: "captions:" <> _, event: "stream.offline"},
                     500
    end

    test "returns 200 when broadcaster user is not found", %{conn: conn, sub: sub} do
      params = %{
        "subscription" => %{"type" => "stream.offline", "id" => sub.subscription_id},
        "event" => %{"broadcaster_user_id" => "nonexistent-uid"}
      }

      conn = post_signed(conn, "notification", params)
      assert conn.status == 200
    end
  end
end
