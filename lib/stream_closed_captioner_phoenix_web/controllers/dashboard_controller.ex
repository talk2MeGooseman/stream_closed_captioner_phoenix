defmodule StreamClosedCaptionerPhoenixWeb.DashboardController do
  use StreamClosedCaptionerPhoenixWeb, :controller
  alias StreamClosedCaptionerPhoenix.Repo

  def index(conn, _params) do
    current_user =
      conn.assigns.current_user
      |> Repo.preload(:stream_settings)

    twitch_enabled = current_user.provider === "twitch" && is_binary(current_user.uid)

    render(conn, "index.html",
      twitch_enabled: twitch_enabled,
      stream_settings: current_user.stream_settings
    )
  end
end
