defmodule StreamClosedCaptionerPhoenix.Settings.StreamSettingsAdmin do
  alias StreamClosedCaptionerPhoenix.Accounts
  alias StreamClosedCaptionerPhoenix.Accounts.UserQueries

  def search_fields(_schema) do
    [
      user: [:email, :username, :uid]
    ]
  end

  def task_stream_settings() do
    [
      # %{
      #   name: "Users with out Stream Settings",
      #   initial_value: 0,
      #   every: 15,
      #   action: fn _v ->
      #     user_ids = UserQueries.get_users_without_settings()
      #     {:ok, user_ids}
      #   end
      # }
    ]
  end

  def widgets(_schema, _conn) do
    [
      %{
        type: "tidbit",
        title: "Users with out Stream Settings",
        content: UserQueries.get_users_without_settings() |> Enum.count(),
        order: 1,
        width: 4,
        icon: ''
      }
    ]
  end

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
