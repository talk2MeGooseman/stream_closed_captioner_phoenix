defmodule StreamClosedCaptionerPhoenixWeb.StreamSettingsLiveTest do
  use StreamClosedCaptionerPhoenixWeb.ConnCase

  import Phoenix.LiveViewTest

  alias StreamClosedCaptionerPhoenix.Settings

  @create_attrs %{caption_delay: 42, filter_profanity: true}
  @update_attrs %{caption_delay: 43, filter_profanity: false}
  @invalid_attrs %{caption_delay: nil, filter_profanity: nil}

  defp fixture(:stream_settings) do
    {:ok, stream_settings} = Settings.create_stream_settings(@create_attrs)
    stream_settings
  end

  defp create_stream_settings(_) do
    stream_settings = fixture(:stream_settings)
    %{stream_settings: stream_settings}
  end

  describe "Index" do
    setup [:create_stream_settings]

    test "lists all stream_settings", %{conn: conn, stream_settings: stream_settings} do
      {:ok, _index_live, html} = live(conn, Routes.stream_settings_index_path(conn, :index))

      assert html =~ "Listing Stream settings"
    end

    test "saves new stream_settings", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, Routes.stream_settings_index_path(conn, :index))

      assert index_live |> element("a[href=\"/stream_settings/new\"]") |> render_click() =~
               "New Stream settings"

      assert_patch(index_live, Routes.stream_settings_index_path(conn, :new))

      assert index_live
             |> form("#stream_settings-form", stream_settings: @invalid_attrs)
             |> render_change() =~ "can&apos;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#stream_settings-form", stream_settings: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.stream_settings_index_path(conn, :index))

      assert html =~ "Stream settings created successfully"
    end

    test "updates stream_settings in listing", %{conn: conn, stream_settings: stream_settings} do
      {:ok, index_live, _html} = live(conn, Routes.stream_settings_index_path(conn, :index))

      assert index_live |> element("#stream_settings-#{stream_settings.id} a", "Edit") |> render_click() =~
               "Edit Stream settings"

      assert_patch(index_live, Routes.stream_settings_index_path(conn, :edit, stream_settings))

      assert index_live
             |> form("#stream_settings-form", stream_settings: @invalid_attrs)
             |> render_change() =~ "can&apos;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#stream_settings-form", stream_settings: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.stream_settings_index_path(conn, :index))

      assert html =~ "Stream settings updated successfully"
    end

    test "deletes stream_settings in listing", %{conn: conn, stream_settings: stream_settings} do
      {:ok, index_live, _html} = live(conn, Routes.stream_settings_index_path(conn, :index))

      assert index_live |> element("#stream_settings-#{stream_settings.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#stream_settings-#{stream_settings.id}")
    end
  end

  describe "Show" do
    setup [:create_stream_settings]

    test "displays stream_settings", %{conn: conn, stream_settings: stream_settings} do
      {:ok, _show_live, html} = live(conn, Routes.stream_settings_show_path(conn, :show, stream_settings))

      assert html =~ "Show Stream settings"
    end

    test "updates stream_settings within modal", %{conn: conn, stream_settings: stream_settings} do
      {:ok, show_live, _html} = live(conn, Routes.stream_settings_show_path(conn, :show, stream_settings))

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Stream settings"

      assert_patch(show_live, Routes.stream_settings_show_path(conn, :edit, stream_settings))

      assert show_live
             |> form("#stream_settings-form", stream_settings: @invalid_attrs)
             |> render_change() =~ "can&apos;t be blank"

      {:ok, _, html} =
        show_live
        |> form("#stream_settings-form", stream_settings: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.stream_settings_show_path(conn, :show, stream_settings))

      assert html =~ "Stream settings updated successfully"
    end
  end
end
