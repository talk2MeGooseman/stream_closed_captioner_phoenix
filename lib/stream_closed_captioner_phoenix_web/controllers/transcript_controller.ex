defmodule StreamClosedCaptionerPhoenixWeb.TranscriptController do
  use StreamClosedCaptionerPhoenixWeb, :controller

  alias StreamClosedCaptionerPhoenix.Accounts
  alias StreamClosedCaptionerPhoenix.Transcripts.Transcript

  def index(conn, _params) do
    transcripts = Accounts.list_transcripts()
    render(conn, "index.html", transcripts: transcripts)
  end

  def new(conn, _params) do
    changeset = Accounts.change_transcript(%Transcript{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"transcript" => transcript_params}) do
    case Accounts.create_transcript(transcript_params) do
      {:ok, transcript} ->
        conn
        |> put_flash(:info, "Transcript created successfully.")
        |> redirect(to: Routes.transcript_path(conn, :show, transcript))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    transcript = Accounts.get_transcript!(id)
    render(conn, "show.html", transcript: transcript)
  end

  def edit(conn, %{"id" => id}) do
    transcript = Accounts.get_transcript!(id)
    changeset = Accounts.change_transcript(transcript)
    render(conn, "edit.html", transcript: transcript, changeset: changeset)
  end

  def update(conn, %{"id" => id, "transcript" => transcript_params}) do
    transcript = Accounts.get_transcript!(id)

    case Accounts.update_transcript(transcript, transcript_params) do
      {:ok, transcript} ->
        conn
        |> put_flash(:info, "Transcript updated successfully.")
        |> redirect(to: Routes.transcript_path(conn, :show, transcript))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", transcript: transcript, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    transcript = Accounts.get_transcript!(id)
    {:ok, _transcript} = Accounts.delete_transcript(transcript)

    conn
    |> put_flash(:info, "Transcript deleted successfully.")
    |> redirect(to: Routes.transcript_path(conn, :index))
  end
end
