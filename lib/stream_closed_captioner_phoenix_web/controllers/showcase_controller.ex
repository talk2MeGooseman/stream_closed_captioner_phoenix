defmodule StreamClosedCaptionerPhoenixWeb.ShowcaseController do
  use StreamClosedCaptionerPhoenixWeb, :controller

  alias StreamClosedCaptionerPhoenixWeb.Layouts

  @sorts ~w(views fewest az)

  @spec index(Plug.Conn.t(), map) :: Plug.Conn.t()
  def index(conn, params) do
    active_channel_ids = StreamClosedCaptionerPhoenixWeb.UserTracker.recently_active_channels()

    # Fetch information about the channels to display from the Twitch API
    stream_list = Twitch.get_live_streams(active_channel_ids)

    sort = sort_param(params)

    conn
    |> put_root_layout(html: {Layouts, :scc_root})
    |> put_layout(html: {Layouts, :scc})
    |> assign(:scc_active, "showcase")
    |> assign(:page_title, "Showcase · Live Twitch streams")
    |> assign(:sort, sort)
    |> render("index.html", data: sort_streams(stream_list, sort))
  end

  defp sort_param(%{"sort" => sort}) when sort in @sorts, do: sort
  defp sort_param(_params), do: "views"

  defp sort_streams(streams, "fewest"), do: Enum.sort_by(streams, & &1.viewer_count, :asc)
  defp sort_streams(streams, "az"), do: Enum.sort_by(streams, &String.downcase(&1.user_name))
  defp sort_streams(streams, _views), do: Enum.sort_by(streams, & &1.viewer_count, :desc)
end
