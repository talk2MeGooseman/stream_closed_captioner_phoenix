defmodule StreamClosedCaptionerPhoenixWeb.TranscirptsLiveTest do
  use StreamClosedCaptionerPhoenixWeb.ConnCase

  import Phoenix.LiveViewTest
  import StreamClosedCaptionerPhoenix.CaptionsFixtures

  @create_attrs %{}
  @update_attrs %{}
  @invalid_attrs %{}

  defp create_transcirpts(_) do
    transcirpts = transcirpts_fixture()
    %{transcirpts: transcirpts}
  end

  describe "Show" do
    setup [:create_transcirpts]

    test "displays transcirpts", %{conn: conn, transcirpts: transcirpts} do
      {:ok, _show_live, html} = live(conn, ~p"/transcripts/#{transcirpts}")

      assert html =~ "Show Transcirpts"
    end

    test "updates transcirpts within modal", %{conn: conn, transcirpts: transcirpts} do
      {:ok, show_live, _html} = live(conn, ~p"/transcripts/#{transcirpts}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Transcirpts"

      assert_patch(show_live, ~p"/transcripts/#{transcirpts}/show/edit")

      assert show_live
             |> form("#transcirpts-form", transcirpts: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#transcirpts-form", transcirpts: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/transcripts/#{transcirpts}")

      html = render(show_live)
      assert html =~ "Transcirpts updated successfully"
    end
  end
end
