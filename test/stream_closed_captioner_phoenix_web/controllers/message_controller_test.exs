defmodule StreamClosedCaptionerPhoenixWeb.MessageControllerTest do
  import StreamClosedCaptionerPhoenix.Factory

  use StreamClosedCaptionerPhoenixWeb.ConnCase, async: true

  setup :register_and_log_in_user

  @update_attrs %{text: "some updated text"}
  @invalid_attrs %{text: nil}

  def fixture(:message, user) do
    transcript = insert(:transcript, user: user)
    insert(:message, transcript: transcript)
  end

  describe "edit message" do
    setup [:create_message]

    test "renders form for editing chosen message", %{conn: conn, message: message} do
      conn =
        get(conn, Routes.transcript_message_path(conn, :edit, message.transcript_id, message.id))

      assert html_response(conn, 200) =~ "Edit Message"
    end
  end

  describe "update message" do
    setup [:create_message]

    test "redirects when data is valid", %{conn: conn, message: message} do
      conn =
        put(
          conn,
          Routes.transcript_message_path(conn, :update, message.transcript_id, message),
          message: @update_attrs
        )

      assert redirected_to(conn) ==
               Routes.transcript_message_path(conn, :edit, message.transcript_id, message)

      conn =
        get(conn, Routes.transcript_message_path(conn, :edit, message.transcript_id, message))

      assert html_response(conn, 200) =~ "some updated text"
    end

    test "renders errors when data is invalid", %{conn: conn, message: message} do
      conn =
        put(
          conn,
          Routes.transcript_message_path(conn, :update, message.transcript_id, message),
          message: @invalid_attrs
        )

      assert html_response(conn, 200) =~ "Edit Message"
    end
  end

  describe "delete message" do
    setup [:create_message]

    test "deletes chosen message", %{conn: conn, message: message} do
      conn =
        delete(
          conn,
          Routes.transcript_message_path(conn, :delete, message.transcript_id, message)
        )

      assert redirected_to(conn) == Routes.transcript_path(conn, :show, message.transcript_id)

      assert_error_sent 404, fn ->
        get(conn, Routes.transcript_message_path(conn, :edit, message.transcript_id, message))
      end
    end
  end

  defp create_message(%{conn: _conn, user: user}) do
    message = fixture(:message, user)
    %{message: message}
  end
end
