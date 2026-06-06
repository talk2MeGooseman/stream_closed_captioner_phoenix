defmodule StreamClosedCaptionerPhoenixWeb.DashboardController do
  use StreamClosedCaptionerPhoenixWeb, :controller
  alias StreamClosedCaptionerPhoenix.Bits
  alias StreamClosedCaptionerPhoenix.Repo
  alias StreamClosedCaptionerPhoenix.Settings
  alias StreamClosedCaptionerPhoenixWeb.Layouts

  def index(conn, _params) do
    current_user =
      conn.assigns.current_user
      |> Repo.preload([:stream_settings, :bits_balance])

    twitch_enabled = current_user.provider === "twitch" && is_binary(current_user.uid)

    conn
    # Bare-tuple form so it replaces the `:logged_in` pipeline's root layout,
    # which is set the same way; a `[html: ...]` form would be shadowed by the
    # pipeline's catch-all. See ShowcaseController for the full why.
    |> put_root_layout({Layouts, :scc_root})
    |> put_layout(html: {Layouts, :scc})
    |> assign(:scc_active, "dashboard")
    |> assign(:page_title, "Dashboard")
    |> render("index.html",
      twitch_enabled: twitch_enabled,
      stream_settings: current_user.stream_settings,
      translation_active: Bits.get_user_active_debit(current_user.id),
      bits_balance: current_user.bits_balance.balance,
      translate_languages: Settings.get_formatted_translate_languages_by_user(current_user.id),
      announcement: StreamClosedCaptionerPhoenix.Announcement |> Repo.first()
    )
  end
end
