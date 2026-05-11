defmodule StreamClosedCaptionerPhoenixWeb.CaptionsChannelTelemetryTest do
  use StreamClosedCaptionerPhoenixWeb.ChannelCase

  import StreamClosedCaptionerPhoenix.Factory
  alias StreamClosedCaptionerPhoenix.TelemetryCapture

  test "join/3 emits [:scc, :captions, :channel, :join] with result: :ok" do
    TelemetryCapture.attach([[:scc, :captions, :channel, :join]])

    stream_settings = insert(:stream_settings, user: build(:bare_user))
    user = stream_settings.user

    {:ok, _, _socket} =
      StreamClosedCaptionerPhoenixWeb.UserSocket
      |> socket("user_id", %{current_user: user})
      |> subscribe_and_join(
        StreamClosedCaptionerPhoenixWeb.CaptionsChannel,
        "captions:#{user.id}"
      )

    assert_receive {:telemetry,
                    [:scc, :captions, :channel, :join],
                    %{count: 1},
                    %{user_id: uid, result: :ok}}

    assert uid == user.id
  end

  test "join/3 emits [:scc, :captions, :channel, :join] with result: :unauthorized" do
    TelemetryCapture.attach([[:scc, :captions, :channel, :join]])

    authorized = insert(:user)
    intruder = insert(:user, stream_settings: nil)

    {:error, %{reason: "unauthorized"}} =
      StreamClosedCaptionerPhoenixWeb.UserSocket
      |> socket("user_id", %{current_user: intruder})
      |> subscribe_and_join(
        StreamClosedCaptionerPhoenixWeb.CaptionsChannel,
        "captions:#{authorized.id}"
      )

    assert_receive {:telemetry,
                    [:scc, :captions, :channel, :join],
                    %{count: 1},
                    %{result: :unauthorized}}
  end

  test "terminate/2 emits [:scc, :captions, :channel, :leave]" do
    TelemetryCapture.attach([[:scc, :captions, :channel, :leave]])

    stream_settings = insert(:stream_settings, user: build(:bare_user))
    user = stream_settings.user

    {:ok, _, socket} =
      StreamClosedCaptionerPhoenixWeb.UserSocket
      |> socket("user_id", %{current_user: user})
      |> subscribe_and_join(
        StreamClosedCaptionerPhoenixWeb.CaptionsChannel,
        "captions:#{user.id}"
      )

    Process.unlink(socket.channel_pid)
    close(socket)

    assert_receive {:telemetry,
                    [:scc, :captions, :channel, :leave],
                    %{count: 1},
                    %{user_id: uid}}

    assert uid == user.id
  end

  describe "[:scc, :captions, :channel, :publish]" do
    setup do
      stream_settings = insert(:stream_settings, user: build(:bare_user))
      user = stream_settings.user

      {:ok, _, socket} =
        StreamClosedCaptionerPhoenixWeb.UserSocket
        |> socket("user_id", %{current_user: user})
        |> subscribe_and_join(
          StreamClosedCaptionerPhoenixWeb.CaptionsChannel,
          "captions:#{user.id}"
        )

      %{socket: socket, user: user}
    end

    test "emits with destination: :default when no zoom/twitch flags", %{socket: socket} do
      TelemetryCapture.attach([[:scc, :captions, :channel, :publish]])

      push(socket, "publishFinal", %{
        "interim" => "hi",
        "final" => "there",
        "session" => "abc"
      })

      assert_receive {:telemetry,
                      [:scc, :captions, :channel, :publish],
                      %{count: 1},
                      %{destination: :default, event: "publishFinal"}},
                     1_000
    end

    test "emits with destination: :twitch and client_send_age_ms when sentOn is present",
         %{socket: socket} do
      TelemetryCapture.attach([[:scc, :captions, :channel, :publish]])

      sent_on = DateTime.utc_now() |> DateTime.add(-2, :second) |> DateTime.to_iso8601()

      push(socket, "publishFinal", %{
        "interim" => "hi",
        "final" => "there",
        "session" => "abc",
        "twitch" => %{"enabled" => true},
        "sentOn" => sent_on
      })

      assert_receive {:telemetry,
                      [:scc, :captions, :channel, :publish],
                      %{count: 1, client_send_age_ms: age},
                      %{destination: :twitch}},
                     1_000

      assert age >= 1_500
    end

    test "active does NOT trigger pipeline events", %{socket: socket} do
      TelemetryCapture.attach([[:scc, :captions, :pipeline, :stop]])
      push(socket, "active", %{})
      refute_receive {:telemetry, [:scc, :captions, :pipeline, :stop], _, _}, 200
    end
  end

  describe "[:scc, :captions, :channel, :reply, :stop] and twitch_publish" do
    setup do
      stream_settings = insert(:stream_settings, user: build(:bare_user))
      user = stream_settings.user

      {:ok, _, socket} =
        StreamClosedCaptionerPhoenixWeb.UserSocket
        |> socket("user_id", %{current_user: user})
        |> subscribe_and_join(
          StreamClosedCaptionerPhoenixWeb.CaptionsChannel,
          "captions:#{user.id}"
        )

      %{socket: socket, user: user}
    end

    test "wraps handle_in in :reply :stop span", %{socket: socket} do
      TelemetryCapture.attach([[:scc, :captions, :channel, :reply, :stop]])

      push(socket, "publishFinal", %{
        "interim" => "hi",
        "final" => "there",
        "session" => "abc"
      })

      assert_receive {:telemetry,
                      [:scc, :captions, :channel, :reply, :stop],
                      %{duration: _},
                      %{destination: :default, event: "publishFinal", result: :ok}},
                     1_000
    end

    test "emits :twitch_publish after Absinthe publish on twitch path", %{
      socket: socket,
      user: user
    } do
      TelemetryCapture.attach([[:scc, :outbound, :twitch_publish, :stop]])

      push(socket, "publishFinal", %{
        "interim" => "hi",
        "final" => "there",
        "session" => "abc",
        "twitch" => %{"enabled" => true}
      })

      assert_receive {:telemetry,
                      [:scc, :outbound, :twitch_publish, :stop],
                      %{count: 1},
                      %{user_id: uid}},
                     1_000

      assert uid == user.id
    end
  end
end
