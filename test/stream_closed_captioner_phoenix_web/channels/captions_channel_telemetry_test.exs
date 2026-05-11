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
end
