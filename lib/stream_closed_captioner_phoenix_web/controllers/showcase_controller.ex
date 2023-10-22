defmodule StreamClosedCaptionerPhoenixWeb.ShowcaseController do
  use StreamClosedCaptionerPhoenixWeb, :controller

  @spec index(Plug.Conn.t(), any) :: Plug.Conn.t()
  def index(conn, _params) do
    active_channel_ids =
      StreamClosedCaptionerPhoenixWeb.UserTracker.recently_active_channels()
      |> Enum.map(fn {uid, _} -> uid end)

    # Fetch information about the channel to display for Twitch API
    stream_list = Twitch.get_live_streams(active_channel_ids)

    # Send the data to the front end
    render(conn, "index.html", data: stream_list)
  end
end
