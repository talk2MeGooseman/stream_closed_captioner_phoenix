defmodule StreamClosedCaptionerPhoenix.Settings.StreamSettingsAdmin do
  alias StreamClosedCaptionerPhoenix.Accounts

  def plural_name(_) do
    "Stream Settings"
  end

  def ordering(_schema) do
    [asc: :id]
  end

  def get_user(%{user_id: id}) do
    id
    |> Accounts.get_user!()
    |> Map.get(:username)
  end

  def index(_) do
    [
      user_id: %{name: "User", value: fn p -> get_user(p) end},
      caption_delay: nil,
      cc_box_size: nil,
      filter_profanity: nil,
      hide_text_on_load: nil,
      language: nil,
      pirate_mode: nil,
      showcase: nil,
      switch_settings_position: nil,
      text_uppercase: nil
    ]
  end

  def form_fields(_) do
    [
      user_id: %{update: :readonly},
      caption_delay: nil,
      cc_box_size: nil,
      filter_profanity: nil,
      hide_text_on_load: nil,
      language: nil,
      pirate_mode: nil,
      showcase: nil,
      switch_settings_position: nil,
      text_uppercase: nil
    ]
  end
end
