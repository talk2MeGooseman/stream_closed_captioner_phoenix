defmodule StreamClosedCaptionerPhoenixWeb.CaptionSettingsLiveTest do
  use StreamClosedCaptionerPhoenixWeb.ConnCase, async: true

  import Mox
  import Phoenix.LiveViewTest

  alias StreamClosedCaptionerPhoenix.Settings

  setup :verify_on_exit!
  setup :register_and_log_in_user

  describe "mount" do
    test "renders the caption settings page in the new design", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/users/caption-settings")

      # page header + the four section cards
      assert html =~ "Stream Settings"
      assert html =~ "Caption Settings"
      assert html =~ "Twitch Overlay"
      assert html =~ "Translation"
      assert html =~ "Blocklist Words"
      assert html =~ "No words added yet"
    end

    test "uses the shared scc chrome, not the old app sidebar", %{conn: conn} do
      html = conn |> get("/users/caption-settings") |> html_response(200)

      assert html =~ "scc-home"
      assert html =~ "Erik Guzman"
      assert html =~ ">Dashboard</a>"
      refute html =~ "sideBar"
    end
  end

  describe "blocklist word management" do
    test "adds a word to the blocklist", %{conn: conn, user: user} do
      {:ok, view, _html} = live(conn, "/users/caption-settings")

      html = render_hook(view, "add", %{"stream_settings" => %{"blocklist_word" => "badword"}})

      assert html =~ "Blocklist word added successfully."
      assert html =~ "badword"

      settings = Settings.get_stream_settings_by_user_id!(user.id)
      assert "badword" in settings.blocklist
    end

    test "ignores an empty blocklist word submission", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/users/caption-settings")

      html = render_hook(view, "add", %{"stream_settings" => %{"blocklist_word" => ""}})

      refute html =~ "Blocklist word added successfully."
      assert html =~ "No words added yet"
    end

    test "removes a word from the blocklist", %{conn: conn, user: user} do
      stream_settings = Settings.get_stream_settings_by_user_id!(user.id)
      {:ok, _} = Settings.update_stream_settings(stream_settings, %{blocklist: ["badword"]})

      {:ok, view, html} = live(conn, "/users/caption-settings")
      assert html =~ "badword"

      html = render_hook(view, "remove_blocklist_word", %{"word" => "badword"})

      assert html =~ "Blocklist word removed successfully."
      refute html =~ "badword"

      settings = Settings.get_stream_settings_by_user_id!(user.id)
      refute "badword" in settings.blocklist
    end
  end

  describe "translation language management" do
    test "creates a translation language when none is set", %{conn: conn, user: user} do
      {:ok, view, _html} = live(conn, "/users/caption-settings")

      html = render_hook(view, "add", %{"translate_language" => %{"language" => "es"}})

      assert html =~ "Updated translation language."

      languages = Settings.get_translate_languages_by_user(user.id)
      assert length(languages) == 1
      assert hd(languages).language == "es"
    end

    test "updates an existing translation language", %{conn: conn, user: user} do
      {:ok, _lang} = Settings.create_translate_language(user, %{"language" => "es"})

      {:ok, view, _html} = live(conn, "/users/caption-settings")

      html = render_hook(view, "add", %{"translate_language" => %{"language" => "fr"}})

      assert html =~ "Updated translation language."

      languages = Settings.get_translate_languages_by_user(user.id)
      assert length(languages) == 1
      assert hd(languages).language == "fr"
    end
  end

  describe "form component - save settings" do
    test "saves caption settings via the form", %{conn: conn, user: user} do
      {:ok, view, _html} = live(conn, "/users/caption-settings")

      view
      |> form("#caption_settings-form", stream_settings: %{pirate_mode: true})
      |> render_submit()

      settings = Settings.get_stream_settings_by_user_id!(user.id)
      assert settings.pirate_mode == true
    end

    test "saves filter_profanity setting", %{conn: conn, user: user} do
      {:ok, view, _html} = live(conn, "/users/caption-settings")

      view
      |> form("#caption_settings-form", stream_settings: %{filter_profanity: true})
      |> render_submit()

      settings = Settings.get_stream_settings_by_user_id!(user.id)
      assert settings.filter_profanity == true
    end

    test "saves hide_text_on_load setting", %{conn: conn, user: user} do
      {:ok, view, _html} = live(conn, "/users/caption-settings")

      view
      |> form("#caption_settings-form", stream_settings: %{hide_text_on_load: true})
      |> render_submit()

      settings = Settings.get_stream_settings_by_user_id!(user.id)
      assert settings.hide_text_on_load == true
    end

    test "saves turn_on_reminder setting", %{conn: conn, user: user} do
      stub(Twitch.MockOauth, :get_client_access_token, fn ->
        {:ok, %{access_token: "test_token"}}
      end)

      stub(Twitch.MockHelix, :eventsub_subscribe, fn _creds,
                                                     _transport,
                                                     type,
                                                     _version,
                                                     _condition ->
        {:ok, %{"data" => [%{"id" => "sub_#{type}"}]}}
      end)

      {:ok, view, _html} = live(conn, "/users/caption-settings")

      view
      |> form("#caption_settings-form", stream_settings: %{turn_on_reminder: true})
      |> render_submit()

      settings = Settings.get_stream_settings_by_user_id!(user.id)
      assert settings.turn_on_reminder == true
    end

    test "saves spoken language change", %{conn: conn, user: user} do
      {:ok, view, _html} = live(conn, "/users/caption-settings")

      view
      |> form("#caption_settings-form", stream_settings: %{language: "es-ES"})
      |> render_submit()

      settings = Settings.get_stream_settings_by_user_id!(user.id)
      assert settings.language == "es-ES"
    end

    test "does not save invalid caption_delay and renders errors", %{conn: conn, user: user} do
      {:ok, view, _html} = live(conn, "/users/caption-settings")
      original_settings = Settings.get_stream_settings_by_user_id!(user.id)

      html =
        view
        |> form("#caption_settings-form", stream_settings: %{caption_delay: -5})
        |> render_submit()

      assert html =~ "must be greater than or equal to 0"
      refute html =~ "Stream settings updated successfully"

      settings = Settings.get_stream_settings_by_user_id!(user.id)
      assert settings.caption_delay == original_settings.caption_delay
    end
  end

  describe "form component - validate event" do
    test "shows validation error for negative caption_delay without saving", %{
      conn: conn,
      user: user
    } do
      {:ok, view, _html} = live(conn, "/users/caption-settings")
      original_settings = Settings.get_stream_settings_by_user_id!(user.id)

      html =
        view
        |> form("#caption_settings-form", stream_settings: %{caption_delay: -1})
        |> render_change()

      assert html =~ "must be greater than or equal to 0"
      refute html =~ "Stream settings updated successfully"

      settings = Settings.get_stream_settings_by_user_id!(user.id)
      assert settings.caption_delay == original_settings.caption_delay
    end
  end
end
