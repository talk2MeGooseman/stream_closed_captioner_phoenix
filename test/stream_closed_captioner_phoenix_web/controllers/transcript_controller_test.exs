defmodule StreamClosedCaptionerPhoenixWeb.TranscriptControllerTest do
  import StreamClosedCaptionerPhoenix.Factory
  use StreamClosedCaptionerPhoenixWeb.ConnCase

  setup :register_and_log_in_user

  @update_attrs %{name: "some updated name", session: "some updated session"}
  @invalid_attrs %{name: nil, session: nil, user_id: nil}

  def fixture(:transcript, user) do
    insert(:transcript, user: user)
  end

  describe "index" do
    test "lists all transcripts", %{conn: conn} do
      conn = get(conn, Routes.transcript_path(conn, :index))
      assert html_response(conn, 200) =~ "Listing Transcripts"
    end
  end

  describe "edit transcript" do
    setup [:create_transcript]

    test "renders form for editing chosen transcript", %{conn: conn, transcript: transcript} do
      conn = get(conn, Routes.transcript_path(conn, :edit, transcript))
      assert html_response(conn, 200) =~ "Edit Transcript"
    end
  end

  describe "update transcript" do
    setup [:create_transcript]

    test "redirects when data is valid", %{conn: conn, transcript: transcript} do
      conn =
        put(conn, Routes.transcript_path(conn, :update, transcript), transcript: @update_attrs)

      assert redirected_to(conn) == Routes.transcript_path(conn, :show, transcript)

      conn = get(conn, Routes.transcript_path(conn, :show, transcript))
      assert html_response(conn, 200) =~ "some updated name"
    end

    test "renders errors when data is invalid", %{conn: conn, transcript: transcript} do
      conn =
        put(conn, Routes.transcript_path(conn, :update, transcript), transcript: @invalid_attrs)

      assert html_response(conn, 200) =~ "Edit Transcript"
    end

    test "renders errors when try to update a transcript that doesnt belong to the user", %{
      conn: conn
    } do
      new_transcript = insert(:transcript)

      assert_raise Ecto.NoResultsError, fn ->
        put(conn, Routes.transcript_path(conn, :update, new_transcript),
          transcript: @invalid_attrs
        )
      end
    end
  end

  describe "delete transcript" do
    setup [:create_transcript]

    test "deletes chosen transcript", %{conn: conn, user: _user, transcript: transcript} do
      conn = delete(conn, Routes.transcript_path(conn, :delete, transcript))
      assert redirected_to(conn) == Routes.transcript_path(conn, :index)

      assert_error_sent 404, fn ->
        get(conn, Routes.transcript_path(conn, :show, transcript))
      end
    end
  end

  defp create_transcript(%{conn: _conn, user: user}) do
    transcript = fixture(:transcript, user)
    %{transcript: transcript}
  end
end
