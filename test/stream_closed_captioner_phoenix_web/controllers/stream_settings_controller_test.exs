defmodule StreamClosedCaptionerPhoenixWeb.StreamSettingsControllerTest do
  import StreamClosedCaptionerPhoenix.Factory
  use StreamClosedCaptionerPhoenixWeb.ConnCase

  setup :register_and_log_in_user

  alias StreamClosedCaptionerPhoenix.Settings

  @update_attrs %{
    caption_delay: 43,
    cc_box_size: false,
    filter_profanity: false,
    hide_text_on_load: false,
    language: "some updated language",
    pirate_mode: false,
    showcase: false,
    switch_settings_position: false,
    text_uppercase: false,
    user_id: 43
  }
  @invalid_attrs %{
    caption_delay: nil,
    cc_box_size: nil,
    filter_profanity: nil,
    hide_text_on_load: nil,
    language: nil,
    pirate_mode: nil,
    showcase: nil,
    switch_settings_position: nil,
    text_uppercase: nil,
    user_id: nil
  }

  def fixture(:stream_settings, user) do
    attrs = %{
      caption_delay: 42,
      cc_box_size: true,
      filter_profanity: true,
      hide_text_on_load: true,
      language: "some language",
      pirate_mode: true,
      showcase: true,
      switch_settings_position: true,
      text_uppercase: true,
      user_id: user.id
    }

    {:ok, stream_settings} = Settings.create_stream_settings(attrs)
    stream_settings
  end

  describe "edit stream_settings" do
    setup [:create_stream_settings]

    test "renders form for editing chosen stream_settings", %{
      conn: conn
    } do
      conn = get(conn, Routes.stream_settings_path(conn, :edit))
      assert html_response(conn, 200) =~ "Edit Stream settings"
    end

    test "redirects if user is not logged in" do
      conn = build_conn()
      conn = get(conn, Routes.stream_settings_path(conn, :edit))
      assert redirected_to(conn) == Routes.user_session_path(conn, :new)
    end
  end

  describe "update stream_settings" do
    setup [:create_stream_settings]

    test "redirects when data is valid", %{conn: conn} do
      conn = put(conn, Routes.stream_settings_path(conn, :update), stream_settings: @update_attrs)

      assert redirected_to(conn) == Routes.stream_settings_path(conn, :edit)

      conn = get(conn, Routes.stream_settings_path(conn, :edit))
      assert html_response(conn, 200) =~ "some updated language"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn =
        put(conn, Routes.stream_settings_path(conn, :update), stream_settings: @invalid_attrs)

      assert html_response(conn, 200) =~ "Edit Stream settings"
    end

    test "redirects if user is not logged in" do
      conn = build_conn()

      conn = put(conn, Routes.stream_settings_path(conn, :update), stream_settings: @update_attrs)

      assert redirected_to(conn) == Routes.user_session_path(conn, :new)
    end
  end

  defp create_stream_settings(%{conn: _conn, user: user}) do
    stream_settings = insert(:stream_settings, user: user)
    %{stream_settings: stream_settings}
  end
end
