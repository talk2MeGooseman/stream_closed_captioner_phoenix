defmodule StreamClosedCaptionerPhoenixWeb.TranscriptController do
  use StreamClosedCaptionerPhoenixWeb, :controller

  alias StreamClosedCaptionerPhoenix.Transcripts

  def index(conn, _params) do
    user = conn.assigns.current_user
    transcripts = Transcripts.list_user_transcripts(user)
    render(conn, "index.html", transcripts: transcripts)
  end

  def show(conn, %{"id" => id}) do
    user = conn.assigns.current_user

    transcript = Transcripts.get_users_transcript!(user, id)
    render(conn, "show.html", transcript: transcript)
  end

  def edit(conn, %{"id" => id}) do
    user = conn.assigns.current_user

    transcript = Transcripts.get_users_transcript!(user, id)
    changeset = Transcripts.change_transcript(transcript)
    render(conn, "edit.html", transcript: transcript, changeset: changeset)
  end

  def update(conn, %{"id" => id, "transcript" => transcript_params}) do
    user = conn.assigns.current_user

    transcript = Transcripts.get_users_transcript!(user, id)

    case Transcripts.update_transcript(transcript, transcript_params) do
      {:ok, transcript} ->
        conn
        |> put_flash(:info, "Transcript updated successfully.")
        |> redirect(to: Routes.transcript_path(conn, :show, transcript))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", transcript: transcript, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    user = conn.assigns.current_user

    transcript = Transcripts.get_users_transcript!(user, id)
    {:ok, _transcript} = Transcripts.delete_transcript(transcript)

    conn
    |> put_flash(:info, "Transcript deleted successfully.")
    |> redirect(to: Routes.transcript_path(conn, :index))
  end
end
