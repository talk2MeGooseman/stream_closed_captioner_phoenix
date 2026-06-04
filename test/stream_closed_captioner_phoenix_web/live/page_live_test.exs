defmodule StreamClosedCaptionerPhoenixWeb.PageLiveTest do
  use StreamClosedCaptionerPhoenixWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "renders the homepage (disconnected and connected)", %{conn: conn} do
    {:ok, page_live, disconnected_html} = live(conn, "/")

    for copy <- [
          "Add closed captions",
          "Everything your captions need",
          "From install to live in four steps",
          "Free, forever."
        ] do
      assert disconnected_html =~ copy
      assert render(page_live) =~ copy
    end
  end

  test "shows the base and enhanced feature tiers", %{conn: conn} do
    {:ok, _page_live, html} = live(conn, "/")

    # base tier
    assert html =~ "Captions for Twitch"
    assert html =~ "Captions for Zoom"
    assert html =~ "Streamer &amp; viewer settings"

    # enhanced tier
    assert html =~ "Translation with Bits"
    assert html =~ "Captions in your VODs"
    assert html =~ "+ Enhanced"
  end

  test "logged-out nav shows the auth CTAs", %{conn: conn} do
    {:ok, _page_live, html} = live(conn, "/")

    assert html =~ "Connect with Twitch"
    assert html =~ "Log in"
    refute html =~ ">Dashboard<"
  end

  describe "when logged in" do
    setup :register_and_log_in_user

    test "nav shows the dashboard link instead of the auth CTAs", %{conn: conn} do
      {:ok, _page_live, html} = live(conn, "/")

      assert html =~ ">Dashboard</a>"
      refute html =~ "Connect with Twitch"
    end
  end
end
