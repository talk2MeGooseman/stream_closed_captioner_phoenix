defmodule StreamClosedCaptionerPhoenixWeb.CaptionsChannelTest do
  # async: false required because channel process makes DB calls through the pipeline
  use StreamClosedCaptionerPhoenixWeb.ChannelCase

  import StreamClosedCaptionerPhoenix.Factory

  setup do
    stream_settings = insert(:stream_settings, user: build(:bare_user))

    {:ok, _, socket} =
      StreamClosedCaptionerPhoenixWeb.UserSocket
      |> socket("user_id", %{current_user: stream_settings.user})
      |> subscribe_and_join(
        StreamClosedCaptionerPhoenixWeb.CaptionsChannel,
        "captions:#{stream_settings.user.id}"
      )

    %{socket: socket, user: stream_settings.user}
  end

  test "authorized user joins their own channel", %{socket: socket} do
    assert socket
  end

  test "unauthorized user cannot join another user's channel", %{user: authorized_user} do
    intruder = insert(:user, stream_settings: nil)

    assert {:error, %{reason: "unauthorized"}} =
             StreamClosedCaptionerPhoenixWeb.UserSocket
             |> socket("user_id", %{current_user: intruder})
             |> subscribe_and_join(
               StreamClosedCaptionerPhoenixWeb.CaptionsChannel,
               "captions:#{authorized_user.id}"
             )
  end

  test "pushes 'active' and replies :ok", %{socket: socket} do
    ref = push(socket, "active", %{})
    assert_reply ref, :ok
  end

  test "publishFinal without zoom or twitch routes to default pipeline and replies :ok", %{
    socket: socket
  } do
    ref =
      push(socket, "publishFinal", %{
        "interim" => "hello",
        "final" => "world",
        "session" => "abc"
      })

    assert_reply ref, :ok, %{final: "world", interim: "hello"}
  end

  test "publishFinal with twitch enabled routes to twitch pipeline and replies :ok", %{
    socket: socket
  } do
    ref =
      push(socket, "publishFinal", %{
        "interim" => "hello",
        "final" => "world",
        "session" => "abc",
        "twitch" => %{"enabled" => true}
      })

    assert_reply ref, :ok, %{final: "world", interim: "hello"}
  end

  test "publishFinal with malformed sentOn does not crash", %{socket: socket} do
    ref =
      push(socket, "publishFinal", %{
        "interim" => "hello",
        "final" => "world",
        "session" => "abc",
        "twitch" => %{"enabled" => true},
        "sentOn" => "not-a-valid-date"
      })

    assert_reply ref, :ok, %{final: "world", interim: "hello"}
  end

  test "publishFinal returns error when pipeline fails" do
    bad_user = insert(:user, stream_settings: nil)

    import Ecto.Query

    StreamClosedCaptionerPhoenix.Repo.delete_all(
      from(ss in StreamClosedCaptionerPhoenix.Settings.StreamSettings,
        where: ss.user_id == ^bad_user.id
      )
    )

    {:ok, _, bad_socket} =
      StreamClosedCaptionerPhoenixWeb.UserSocket
      |> socket("user_id", %{current_user: bad_user})
      |> subscribe_and_join(
        StreamClosedCaptionerPhoenixWeb.CaptionsChannel,
        "captions:#{bad_user.id}"
      )

    ref =
      push(bad_socket, "publishFinal", %{
        "interim" => "hello",
        "final" => "world",
        "session" => "abc"
      })

    assert_reply ref, :error, "Issue sending captions."
  end

  test "publishFinal with zoom enabled and non-Zoom host URL replies error", %{socket: socket} do
    ref =
      push(socket, "publishFinal", %{
        "interim" => "",
        "final" => "hello",
        "session" => "abc",
        "zoom" => %{"enabled" => true, "url" => "https://evil.example.com/captions", "seq" => 1}
      })

    assert_reply ref, :error, "Issue sending captions."
  end

  test "publishFinal with zoom enabled and non-HTTPS URL replies error", %{socket: socket} do
    ref =
      push(socket, "publishFinal", %{
        "interim" => "",
        "final" => "hello",
        "session" => "abc",
        "zoom" => %{
          "enabled" => true,
          "url" => "http://stream.zoom.us/captions",
          "seq" => 1
        }
      })

    assert_reply ref, :error, "Issue sending captions."
  end

end
