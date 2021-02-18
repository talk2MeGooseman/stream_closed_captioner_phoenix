defmodule StreamClosedCaptionerPhoenixWeb.TranscriptControllerTest do
  use StreamClosedCaptionerPhoenixWeb.ConnCase

  alias StreamClosedCaptionerPhoenix.Accounts

  @create_attrs %{name: "some name", session: "some session", user_id: 42}
  @update_attrs %{name: "some updated name", session: "some updated session", user_id: 43}
  @invalid_attrs %{name: nil, session: nil, user_id: nil}

  def fixture(:transcript) do
    {:ok, transcript} = Accounts.create_transcript(@create_attrs)
    transcript
  end

  describe "index" do
    test "lists all transcripts", %{conn: conn} do
      conn = get(conn, Routes.transcript_path(conn, :index))
      assert html_response(conn, 200) =~ "Listing Transcripts"
    end
  end

  describe "new transcript" do
    test "renders form", %{conn: conn} do
      conn = get(conn, Routes.transcript_path(conn, :new))
      assert html_response(conn, 200) =~ "New Transcript"
    end
  end

  describe "create transcript" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, Routes.transcript_path(conn, :create), transcript: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.transcript_path(conn, :show, id)

      conn = get(conn, Routes.transcript_path(conn, :show, id))
      assert html_response(conn, 200) =~ "Show Transcript"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.transcript_path(conn, :create), transcript: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Transcript"
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
      conn = put(conn, Routes.transcript_path(conn, :update, transcript), transcript: @update_attrs)
      assert redirected_to(conn) == Routes.transcript_path(conn, :show, transcript)

      conn = get(conn, Routes.transcript_path(conn, :show, transcript))
      assert html_response(conn, 200) =~ "some updated name"
    end

    test "renders errors when data is invalid", %{conn: conn, transcript: transcript} do
      conn = put(conn, Routes.transcript_path(conn, :update, transcript), transcript: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Transcript"
    end
  end

  describe "delete transcript" do
    setup [:create_transcript]

    test "deletes chosen transcript", %{conn: conn, transcript: transcript} do
      conn = delete(conn, Routes.transcript_path(conn, :delete, transcript))
      assert redirected_to(conn) == Routes.transcript_path(conn, :index)
      assert_error_sent 404, fn ->
        get(conn, Routes.transcript_path(conn, :show, transcript))
      end
    end
  end

  defp create_transcript(_) do
    transcript = fixture(:transcript)
    %{transcript: transcript}
  end
end
