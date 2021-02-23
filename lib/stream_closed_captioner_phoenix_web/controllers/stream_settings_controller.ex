defmodule StreamClosedCaptionerPhoenixWeb.StreamSettingsController do
  use StreamClosedCaptionerPhoenixWeb, :controller

  alias StreamClosedCaptionerPhoenix.Settings

  def edit(conn, _params) do
    user = conn.assigns.current_user
    stream_settings = Settings.get_stream_settings_by_user_id!(user.id)

    changeset = Settings.change_stream_settings(stream_settings)
    render(conn, "edit.html", stream_settings: stream_settings, changeset: changeset)
  end

  def update(conn, %{"stream_settings" => stream_settings_params}) do
    user = conn.assigns.current_user
    stream_settings = Settings.get_stream_settings_by_user_id!(user.id)

    case Settings.update_stream_settings(stream_settings, stream_settings_params) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Stream settings updated successfully.")
        |> redirect(to: Routes.stream_settings_path(conn, :edit))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", stream_settings: stream_settings, changeset: changeset)
    end
  end
end
