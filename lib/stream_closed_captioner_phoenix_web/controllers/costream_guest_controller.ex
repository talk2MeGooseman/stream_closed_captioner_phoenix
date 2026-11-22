defmodule StreamClosedCaptionerPhoenixWeb.CostreamGuestController do
  @moduledoc """
  Public guest dashboard for co-streamer captions, reached via a per-guest
  shareable link. No account required: the signed token in the URL is the
  entire credential, verified against the guest record (revocation, host
  feature flag) on every load.
  """
  use StreamClosedCaptionerPhoenixWeb, :controller

  alias StreamClosedCaptionerPhoenix.{Costream, Settings}

  def show(conn, %{"token" => token}) do
    case Costream.verify_guest_token(token) do
      {:ok, guest} ->
        render(conn, "show.html",
          guest: guest,
          host: guest.user,
          token: token,
          default_language: host_language(guest.user),
          spoken_languages: Settings.spoken_languages(),
          page_title: "Co-stream captions"
        )

      {:error, _reason} ->
        conn
        |> put_status(:not_found)
        |> render("invalid.html", page_title: "Co-stream captions")
    end
  end

  defp host_language(host) do
    case Settings.get_stream_settings_by_user_id(host.id) do
      {:ok, stream_settings} -> stream_settings.language
      {:error, _} -> "en-US"
    end
  end
end
