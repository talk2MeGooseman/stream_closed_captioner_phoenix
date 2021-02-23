defmodule StreamClosedCaptionerPhoenix.SettingsTest do
  use StreamClosedCaptionerPhoenix.DataCase

  alias StreamClosedCaptionerPhoenix.Settings

  import StreamClosedCaptionerPhoenix.SettingsFixtures
  import StreamClosedCaptionerPhoenix.AccountsFixtures, only: [user_fixture: 0]

  describe "stream_settings" do
    alias StreamClosedCaptionerPhoenix.Settings.StreamSettings

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

    test "list_stream_settings/0 returns all stream_settings" do
      stream_settings = stream_settings_fixture()
      assert Settings.list_stream_settings() == [stream_settings]
    end

    test "get_stream_settings!/1 returns the stream_settings with given id" do
      stream_settings = stream_settings_fixture()
      assert Settings.get_stream_settings!(stream_settings.id) == stream_settings
    end

    test "create_stream_settings/1 with valid data creates a stream_settings" do
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
        user_id: user_fixture().id
      }

      assert {:ok, %StreamSettings{} = stream_settings} =
               Settings.create_stream_settings(attrs)

      assert stream_settings.caption_delay == 42
      assert stream_settings.cc_box_size == true
      assert stream_settings.filter_profanity == true
      assert stream_settings.hide_text_on_load == true
      assert stream_settings.language == "some language"
      assert stream_settings.pirate_mode == true
      assert stream_settings.showcase == true
      assert stream_settings.switch_settings_position == true
      assert stream_settings.text_uppercase == true
      assert stream_settings.user_id == attrs.user_id
    end

    test "create_stream_settings/1 will not create more than one stream settings per user" do
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
        user_id: user_fixture().id
      }

      assert {:ok, %StreamSettings{} = stream_settings} =
               Settings.create_stream_settings(attrs)
      assert {:error, %Ecto.Changeset{} = stream_settings} =
               Settings.create_stream_settings(attrs)
    end

    test "create_stream_settings/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Settings.create_stream_settings(@invalid_attrs)
    end

    test "update_stream_settings/2 with valid data updates the stream_settings but not the user" do
      stream_settings = stream_settings_fixture()

      assert {:ok, %StreamSettings{} = stream_settings} =
               Settings.update_stream_settings(stream_settings, @update_attrs)

      assert stream_settings.caption_delay == 43
      assert stream_settings.cc_box_size == false
      assert stream_settings.filter_profanity == false
      assert stream_settings.hide_text_on_load == false
      assert stream_settings.language == "some updated language"
      assert stream_settings.pirate_mode == false
      assert stream_settings.showcase == false
      assert stream_settings.switch_settings_position == false
      assert stream_settings.text_uppercase == false
      assert stream_settings.user_id == stream_settings.user_id
    end

    test "update_stream_settings/2 with invalid data returns error changeset" do
      stream_settings = stream_settings_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Settings.update_stream_settings(stream_settings, @invalid_attrs)

      assert stream_settings == Settings.get_stream_settings!(stream_settings.id)
    end

    test "delete_stream_settings/1 deletes the stream_settings" do
      stream_settings = stream_settings_fixture()
      assert {:ok, %StreamSettings{}} = Settings.delete_stream_settings(stream_settings)

      assert_raise Ecto.NoResultsError, fn ->
        Settings.get_stream_settings!(stream_settings.id)
      end
    end

    test "change_stream_settings/1 returns a stream_settings changeset" do
      stream_settings = stream_settings_fixture()
      assert %Ecto.Changeset{} = Settings.change_stream_settings(stream_settings)
    end
  end
end
