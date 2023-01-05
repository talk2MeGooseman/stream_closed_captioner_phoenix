defmodule StreamClosedCaptionerPhoenixWeb.DashboardController do
  use StreamClosedCaptionerPhoenixWeb, :controller
  alias StreamClosedCaptionerPhoenix.{Repo, Bits, Settings}

  def index(conn, _params) do
    current_user =
      conn.assigns.current_user
      |> Repo.preload(:stream_settings)
      |> Repo.preload(:bits_balance)

    twitch_enabled = current_user.provider === "twitch" && is_binary(current_user.uid)

    render(conn, "index.html",
      twitch_enabled: twitch_enabled,
      stream_settings: current_user.stream_settings,
      translation_active: Bits.get_user_active_debit(current_user.id),
      bits_balance: current_user.bits_balance.balance,
      translate_languages: Settings.get_formatted_translate_languages_by_user(current_user.id),
      announcement: StreamClosedCaptionerPhoenix.Announcement |> Repo.first()
    )
  end
end
