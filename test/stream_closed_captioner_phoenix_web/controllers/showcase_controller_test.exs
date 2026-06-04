defmodule StreamClosedCaptionerPhoenixWeb.ShowcaseControllerTest do
  use StreamClosedCaptionerPhoenixWeb.ConnCase, async: true

  describe "GET /showcase" do
    test "renders the live-streams showcase in the new design", %{conn: conn} do
      conn = get(conn, ~p"/showcase")
      html = html_response(conn, 200)

      # showcase header
      assert html =~ "Live now"
      assert html =~ "captioning live"
      assert html =~ "Showcase · Live Twitch streams"
      # closing join bar
      assert html =~ "Want your stream on this page?"
    end

    test "renders the shared Stream CC nav and footer chrome", %{conn: conn} do
      html = conn |> get(~p"/showcase") |> html_response(200)

      # nav CTA (logged out) + footer copyright both come from the :scc layout
      assert html =~ "Connect with Twitch"
      assert html =~ "Erik Guzman"
    end

    test "shows the empty state when no channels are live", %{conn: conn} do
      html = conn |> get(~p"/showcase") |> html_response(200)
      assert html =~ "No channels are live right now"
    end

    test "accepts sort options (including unknown values) without error", %{conn: conn} do
      for sort <- ~w(views fewest az something-bogus) do
        html = conn |> get(~p"/showcase?#{[sort: sort]}") |> html_response(200)
        assert html =~ "captioning live"
      end
    end
  end
end
