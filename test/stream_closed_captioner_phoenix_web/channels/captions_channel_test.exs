defmodule StreamClosedCaptionerPhoenixWeb.CaptionsChannelTest do
  use StreamClosedCaptionerPhoenixWeb.ChannelCase, async: true

  import StreamClosedCaptionerPhoenix.Factory

  setup do
    [stream_settings, _] = insert_pair(:stream_settings, user: fn -> build(:user) end)

    {:ok, _, socket} =
      StreamClosedCaptionerPhoenixWeb.UserSocket
      |> socket("user_id", %{current_user: stream_settings.user})
      |> subscribe_and_join(
        StreamClosedCaptionerPhoenixWeb.CaptionsChannel,
        "captions:#{stream_settings.user.id}"
      )

    %{socket: socket}
  end

  # test "ping replies with status ok", %{socket: socket} do
  #   ref =
  #     push(socket, "publish", %{"interim" => "hello", "final" => "goodbye", "session" => "123"})

  #   assert_reply ref, :ok, %{"hello" => "there"}
  # end
end
