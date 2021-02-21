defmodule StreamClosedCaptionerPhoenixWeb.MessageController do
  use StreamClosedCaptionerPhoenixWeb, :controller

  alias StreamClosedCaptionerPhoenix
  alias StreamClosedCaptionerPhoenix.Transcripts

  def show(conn, %{"id" => id}) do
    message =  Transcripts.get_message!(id)
    render(conn, "show.html", message: message)
  end

  def edit(conn, %{"id" => id}) do
    message =  Transcripts.get_message!(id)
    changeset =  Transcripts.change_message(message)
    render(conn, "edit.html", message: message, changeset: changeset)
  end

  def update(conn, %{"id" => id, "message" => message_params}) do
    message =  Transcripts.get_message!(id)

    case  Transcripts.update_message(message, message_params) do
      {:ok, message} ->
        conn
        |> put_flash(:info, "Message updated successfully.")
        |> redirect(to: Routes.transcript_message_path(conn, :show, message.transcript_id, message))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", message: message, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    message =  Transcripts.get_message!(id)
    {:ok, message} =  Transcripts.delete_message(message)

    conn
    |> put_flash(:info, "Message deleted successfully.")
    |> redirect(to: Routes.transcript_path(conn, :show, message.transcript_id))
  end
end
