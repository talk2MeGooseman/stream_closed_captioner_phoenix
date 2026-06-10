defmodule StreamClosedCaptionerPhoenixWeb.CaptionSourceE2ETest do
  @moduledoc """
  Full-stack regression test for the OBS caption source overlay: a caption
  pushed on the real captions channel must come out the other end of the
  pipeline, cross PubSub, and render in the CaptionSourceLive overlay.

  The channel tests and CaptionSourceLive tests each cover their own half of
  this flow with hand-built broadcasts; only this test would catch a topic or
  payload-shape mismatch between the two.
  """
  use StreamClosedCaptionerPhoenixWeb.ConnCase

  import Phoenix.ChannelTest, except: [connect: 2, connect: 3, push: 3]
  import Phoenix.LiveViewTest, except: [assert_reply: 2, assert_reply: 3]
  import StreamClosedCaptionerPhoenix.Factory

  alias StreamClosedCaptionerPhoenix.Settings

  test "a caption pushed on the captions channel renders in the overlay", %{conn: conn} do
    stream_settings = insert(:stream_settings, user: build(:bare_user))
    stream_settings = Settings.get_or_generate_caption_source_token!(stream_settings)

    {:ok, view, _html} = live(conn, "/captions/#{stream_settings.caption_source_token}")

    {:ok, _, socket} =
      StreamClosedCaptionerPhoenixWeb.UserSocket
      |> socket("user_id", %{current_user: stream_settings.user})
      |> subscribe_and_join(
        StreamClosedCaptionerPhoenixWeb.CaptionsChannel,
        "captions:#{stream_settings.user.id}"
      )

    ref =
      Phoenix.ChannelTest.push(socket, "publishFinal", %{
        "interim" => "",
        "final" => "hello overlay",
        "session" => "abc"
      })

    assert_reply ref, :ok

    assert render(view) =~ "hello overlay"
  end
end
