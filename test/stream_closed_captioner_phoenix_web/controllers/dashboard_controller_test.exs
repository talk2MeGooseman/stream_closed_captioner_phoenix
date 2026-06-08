defmodule StreamClosedCaptionerPhoenixWeb.DashboardControllerTest do
  use StreamClosedCaptionerPhoenixWeb.ConnCase, async: true

  setup :register_and_log_in_user

  describe "GET /dashboard" do
    test "renders the console dashboard in the new design", %{conn: conn} do
      html = conn |> get(~p"/dashboard") |> html_response(200)

      assert html =~ "Dashboard"
      assert html =~ "Live Session"
      assert html =~ "Your Captions"
      assert html =~ "System Status"
      assert html =~ "Zoom Meeting Captions"
      assert html =~ "OBS Websocket"
      assert html =~ "Twitch Translation"
    end

    test "preserves the Stimulus caption/output wiring", %{conn: conn} do
      html = conn |> get(~p"/dashboard") |> html_response(200)

      # the live caption control + its start button must keep their hooks
      assert html =~ ~s(data-controller="captions")
      assert html =~ ~s(data-captions-target="start")
      assert html =~ ~s(data-action="click->captions#startCaptions")
      assert html =~ ~s(data-captions-target="outputOutline")
      assert html =~ ~s(data-captions-target="translationOutput")
      # the output destinations keep their controllers
      assert html =~ ~s(data-controller="zoom")
      assert html =~ ~s(data-controller="obs")
      assert html =~ ~s(data-controller="translations")
      assert html =~ ~s(data-zoom-target="onButton")
    end

    test "injects the globals the captions channel needs", %{conn: conn} do
      html = conn |> get(~p"/dashboard") |> html_response(200)

      assert html =~ "window.userId"
      assert html =~ "window.userToken"
    end

    test "uses the shared scc chrome, not the old app sidebar", %{conn: conn} do
      html = conn |> get(~p"/dashboard") |> html_response(200)

      assert html =~ "scc-home"
      assert html =~ "Erik Guzman"
      refute html =~ "sideBar"
    end

    test "shows the connect-twitch output for non-twitch accounts", %{conn: conn} do
      html = conn |> get(~p"/dashboard") |> html_response(200)
      assert html =~ "Connect with Twitch"
    end

    test "translation card keeps its status/balance but no longer renders a captions display section",
         %{conn: conn} do
      html = conn |> get(~p"/dashboard") |> html_response(200)

      {:ok, doc} = Floki.parse_document(html)
      [card] = Floki.find(doc, ~s([data-controller="translations"]))
      card_html = Floki.raw_html(card)

      # status + balance stats stay in the card
      assert [_] = Floki.find(card, ~s([data-translations-target="translationStatus"]))
      assert [_] = Floki.find(card, ~s([data-translations-target="bitsBalance"]))

      # the translated-captions display section (now shown in the Preview stage) is gone
      assert [] = Floki.find(card, ~s([data-translations-target="displayTranslations"]))
      assert [] = Floki.find(card, ~s([data-translations-target="translationsList"]))

      # and the old kutty/Alpine collapse must not have crept back
      refute card_html =~ ~s|x-data="collapse()"|
      refute card_html =~ "x-cloak"
    end
  end
end
