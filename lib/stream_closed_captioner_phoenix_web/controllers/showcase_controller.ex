defmodule StreamClosedCaptionerPhoenixWeb.ShowcaseController do
  use StreamClosedCaptionerPhoenixWeb, :controller

  def index(conn, _params) do
    active_user_map = StreamClosedCaptionerPhoenixWeb.ActivePresence.list("active_channels")
    channel_ids =
      Enum.reduce(active_user_map, [], fn data, acc -> reduced_user_list(data, acc) end)

    # Fetch information about the channel to display for Twitch API
    stream_list = Twitch.get_live_streams(channel_ids)

    # Send the data to the front end
    render(conn, "index.html", data: stream_list)
  end

  defp reduced_user_list({_, %{user: %{uid: uid}}}, acc) when is_binary(uid) do
    # Filter by last publish no more than 5 minutes ago
    [uid | acc]
  end

  defp reduced_user_list(_, acc) do
    acc
  end
end
