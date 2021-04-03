defmodule StreamClosedCaptionerPhoenixWeb.PageLiveTest do
  use StreamClosedCaptionerPhoenixWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  @tag :skip
  test "disconnected and connected render", %{conn: conn} do
    {:ok, page_live, disconnected_html} = live(conn, "/")
    assert disconnected_html =~ "Boilerplate Generator"
    assert render(page_live) =~ "Boilerplate Generator"
  end
end
