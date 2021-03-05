defmodule StreamClosedCaptionerPhoenixWeb.MessageController do
  use StreamClosedCaptionerPhoenixWeb, :controller

  alias StreamClosedCaptionerPhoenix
  alias StreamClosedCaptionerPhoenix.Transcripts

  def edit(conn, %{"transcript_id" => transcript_id, "id" => id}) do
    user = conn.assigns.current_user

    transcript = Transcripts.get_users_transcript!(user, transcript_id)

    message = Transcripts.get_transcripts_message!(transcript, id)
    changeset = Transcripts.change_message(message)
    render(conn, "edit.html", message: message, changeset: changeset)
  end

  @spec update(Plug.Conn.t(), map) :: Plug.Conn.t()
  def update(conn, %{"transcript_id" => transcript_id, "id" => id, "message" => message_params}) do
    user = conn.assigns.current_user

    transcript = Transcripts.get_users_transcript!(user, transcript_id)
    message = Transcripts.get_transcripts_message!(transcript, id)

    case Transcripts.update_message(message, message_params) do
      {:ok, message} ->
        conn
        |> put_flash(:info, "Message updated successfully.")
        |> redirect(
          to: Routes.transcript_message_path(conn, :edit, message.transcript_id, message)
        )

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", message: message, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id, "transcript_id" => transcript_id}) do
    user = conn.assigns.current_user

    transcript = Transcripts.get_users_transcript!(user, transcript_id)
    message = Transcripts.get_transcripts_message!(transcript, id)
    {:ok, message} = Transcripts.delete_message(message)

    conn
    |> put_flash(:info, "Message deleted successfully.")
    |> redirect(to: Routes.transcript_path(conn, :show, message.transcript_id))
  end
end
