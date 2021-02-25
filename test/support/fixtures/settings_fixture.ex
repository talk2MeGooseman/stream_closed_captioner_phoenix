defmodule StreamClosedCaptionerPhoenix.SettingsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `StreamClosedCaptionerPhoenix.Settings` context.
  """

  import StreamClosedCaptionerPhoenix.AccountsFixtures

  def stream_settings_fixture(attrs \\ %{}) do
    {:ok, settings} =
      attrs
      |> Enum.into(%{
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
      })
      |> StreamClosedCaptionerPhoenix.Settings.create_stream_settings()

    settings
  end

  def translate_languages_fixture(attrs \\ %{}) do
    {:ok, translate_languages} =
      attrs
      |> Enum.into(%{language: "en", user_id: user_fixture().id})
      |> StreamClosedCaptionerPhoenix.Settings.create_translate_languages()

    translate_languages
  end
end
