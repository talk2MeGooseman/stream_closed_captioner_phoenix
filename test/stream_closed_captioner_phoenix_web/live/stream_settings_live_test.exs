defmodule StreamClosedCaptionerPhoenixWeb.CaptionSettingsLiveTest do
  use StreamClosedCaptionerPhoenixWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias StreamClosedCaptionerPhoenix.Settings

  setup :register_and_log_in_user

  describe "mount" do
    test "renders the caption settings page", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/users/caption-settings")

      assert html =~ "Caption Settings"
      assert html =~ "Captions Blocklist Words"
      assert html =~ "No words added to your blocklist."
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
      assert html =~ "No words added to your blocklist."
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
    test "saves caption settings via the form", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/users/caption-settings")

      html =
        view
        |> form("#caption_settings-form", stream_settings: %{pirate_mode: true})
        |> render_submit()

      assert html =~ "Stream settings updated successfully"
    end
  end
end
