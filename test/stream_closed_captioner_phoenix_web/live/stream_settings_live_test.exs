# # defmodule StreamClosedCaptionerPhoenixWeb.CaptionSettingsLiveTest do
#   use StreamClosedCaptionerPhoenixWeb.ConnCase

#   import StreamClosedCaptionerPhoenix.Factory
#   import Phoenix.LiveViewTest

#   alias StreamClosedCaptionerPhoenix.Settings

#   @create_attrs %{caption_delay: 42, filter_profanity: true}
#   @update_attrs %{caption_delay: 43, filter_profanity: false}
#   @invalid_attrs %{caption_delay: nil, filter_profanity: nil}

#   defp fixture(:stream_settings) do
#     insert(:stream_settings)
#   end

#   defp create_stream_settings(_) do
#     stream_settings = fixture(:stream_settings)
#     %{stream_settings: stream_settings}
#   end

#   describe "Show" do
#     setup [:create_stream_settings]

#     test "displays stream_settings", %{conn: conn, stream_settings: stream_settings} do
#       {:ok, _show_live, html} =
#         live(conn, Routes.stream_settings_show_path(conn, :show, stream_settings))

#       assert html =~ "Show Stream settings"
#     end

#     test "updates stream_settings within modal", %{conn: conn, stream_settings: stream_settings} do
#       {:ok, show_live, _html} =
#         live(conn, Routes.stream_settings_show_path(conn, :show, stream_settings))

#       assert show_live |> element("a", "Edit") |> render_click() =~
#                "Edit Stream settings"

#       assert_patch(show_live, Routes.stream_settings_show_path(conn, :edit, stream_settings))

#       assert show_live
#              |> form("#stream_settings-form", stream_settings: @invalid_attrs)
#              |> render_change() =~ "can&apos;t be blank"

#       {:ok, _, html} =
#         show_live
#         |> form("#stream_settings-form", stream_settings: @update_attrs)
#         |> render_submit()
#         |> follow_redirect(conn, Routes.stream_settings_show_path(conn, :show, stream_settings))

#       assert html =~ "Stream settings updated successfully"
#     end
#   end
# end
