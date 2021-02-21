defmodule StreamClosedCaptionerPhoenixWeb.TranscriptController do
  use StreamClosedCaptionerPhoenixWeb, :controller

  alias StreamClosedCaptionerPhoenix.Transcripts
  alias StreamClosedCaptionerPhoenix.Transcripts.Transcript

  def index(conn, _params) do
    transcripts = Transcripts.list_transcripts()
    render(conn, "index.html", transcripts: transcripts)
  end


  def show(conn, %{"id" => id}) do
    transcript = Transcripts.get_transcript!(id)
    render(conn, "show.html", transcript: transcript)
  end

  def edit(conn, %{"id" => id}) do
    transcript = Transcripts.get_transcript!(id)
    changeset = Transcripts.change_transcript(transcript)
    render(conn, "edit.html", transcript: transcript, changeset: changeset)
  end

  def update(conn, %{"id" => id, "transcript" => transcript_params}) do
    transcript = Transcripts.get_transcript!(id)

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
    transcript = Transcripts.get_transcript!(id)
    {:ok, _transcript} = Transcripts.delete_transcript(transcript)

    conn
    |> put_flash(:info, "Transcript deleted successfully.")
    |> redirect(to: Routes.transcript_path(conn, :index))
  end
end
