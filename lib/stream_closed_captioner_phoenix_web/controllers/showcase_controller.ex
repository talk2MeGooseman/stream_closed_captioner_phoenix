defmodule StreamClosedCaptionerPhoenixWeb.ShowcaseController do
  use StreamClosedCaptionerPhoenixWeb, :controller

  @spec index(Plug.Conn.t(), any) :: Plug.Conn.t()
  def index(conn, _params) do
    active_users = StreamClosedCaptionerPhoenixWeb.UserTracker.list("active_channels")

    channel_ids = Enum.reduce(active_users, [], fn data, acc -> reduced_user_list(data, acc) end)

    # Fetch information about the channel to display for Twitch API
    stream_list = Twitch.get_live_streams(channel_ids)

    # Send the data to the front end
    render(conn, "index.html", data: stream_list)
  end

  defp reduced_user_list({uid, %{metas: metas}}, acc) when is_binary(uid) do
    last_publish = metas |> List.first() |> Map.get(:last_publish, 0)
    elapased_time = current_timestamp() - last_publish

    if elapased_time <= 300 do
      [uid | acc]
    else
      acc
    end
  end

  defp reduced_user_list(_, acc) do
    acc
  end

  defp current_timestamp, do: System.system_time(:second)
end
