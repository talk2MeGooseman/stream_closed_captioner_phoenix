defmodule StreamClosedCaptionerPhoenixWeb.MessageControllerTest do
  use StreamClosedCaptionerPhoenixWeb.ConnCase

  alias StreamClosedCaptionerPhoenix.Accounts

  @create_attrs %{text: "some text", transcript_id: 42}
  @update_attrs %{text: "some updated text", transcript_id: 43}
  @invalid_attrs %{text: nil, transcript_id: nil}

  def fixture(:message) do
    {:ok, message} = Accounts.create_message(@create_attrs)
    message
  end

  describe "index" do
    test "lists all messages", %{conn: conn} do
      conn = get(conn, Routes.message_path(conn, :index))
      assert html_response(conn, 200) =~ "Listing Messages"
    end
  end

  describe "new message" do
    test "renders form", %{conn: conn} do
      conn = get(conn, Routes.message_path(conn, :new))
      assert html_response(conn, 200) =~ "New Message"
    end
  end

  describe "create message" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, Routes.message_path(conn, :create), message: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.message_path(conn, :show, id)

      conn = get(conn, Routes.message_path(conn, :show, id))
      assert html_response(conn, 200) =~ "Show Message"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.message_path(conn, :create), message: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Message"
    end
  end

  describe "edit message" do
    setup [:create_message]

    test "renders form for editing chosen message", %{conn: conn, message: message} do
      conn = get(conn, Routes.message_path(conn, :edit, message))
      assert html_response(conn, 200) =~ "Edit Message"
    end
  end

  describe "update message" do
    setup [:create_message]

    test "redirects when data is valid", %{conn: conn, message: message} do
      conn = put(conn, Routes.message_path(conn, :update, message), message: @update_attrs)
      assert redirected_to(conn) == Routes.message_path(conn, :show, message)

      conn = get(conn, Routes.message_path(conn, :show, message))
      assert html_response(conn, 200) =~ "some updated text"
    end

    test "renders errors when data is invalid", %{conn: conn, message: message} do
      conn = put(conn, Routes.message_path(conn, :update, message), message: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Message"
    end
  end

  describe "delete message" do
    setup [:create_message]

    test "deletes chosen message", %{conn: conn, message: message} do
      conn = delete(conn, Routes.message_path(conn, :delete, message))
      assert redirected_to(conn) == Routes.message_path(conn, :index)
      assert_error_sent 404, fn ->
        get(conn, Routes.message_path(conn, :show, message))
      end
    end
  end

  defp create_message(_) do
    message = fixture(:message)
    %{message: message}
  end
end
