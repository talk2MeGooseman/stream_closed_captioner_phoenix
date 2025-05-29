defmodule StreamClosedCaptionerPhoenixWeb.DashboardController do
  use StreamClosedCaptionerPhoenixWeb, :controller
  alias StreamClosedCaptionerPhoenix.Bits
  alias StreamClosedCaptionerPhoenix.Repo
  alias StreamClosedCaptionerPhoenix.Settings

  def index(conn, _params) do
    current_user =
      conn.assigns.current_user
      |> Repo.preload([:stream_settings, :bits_balance])

    twitch_enabled = current_user.provider === "twitch" && is_binary(current_user.uid)

    render(conn, "index.html",
      current_user: current_user,
      twitch_enabled: twitch_enabled,
      stream_settings: current_user.stream_settings,
      translation_active: Bits.get_user_active_debit(current_user.id),
      bits_balance: current_user.bits_balance.balance,
      translate_languages: Settings.get_formatted_translate_languages_by_user(current_user.id),
      announcement: StreamClosedCaptionerPhoenix.Announcement |> Repo.first()
    )
  end

  def toggle_translation(conn, _params) do
    current_user = conn.assigns.current_user
    {:ok, stream_settings} = Settings.get_stream_settings_by_user_id(current_user.id)
    
    case Settings.update_stream_settings(stream_settings, %{translation_enabled: !stream_settings.translation_enabled}) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Translation setting updated successfully.")
        |> redirect(to: "/dashboard")

      {:error, _} ->
        conn
        |> put_flash(:error, "Failed to update translation setting.")
        |> redirect(to: "/dashboard")
    end
  end
end
