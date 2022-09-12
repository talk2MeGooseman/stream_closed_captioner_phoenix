defmodule StreamClosedCaptionerPhoenix.Settings.StreamSettings do
  use Ecto.Schema
  import Ecto.Changeset

  schema "stream_settings" do
    field(:blocklist, {:array, :string}, default: [])
    field(:caption_delay, :integer)
    field(:cc_box_size, :boolean, default: false)
    field(:filter_profanity, :boolean, default: false)
    field(:hide_text_on_load, :boolean, default: false)
    field(:language, :string)
    field(:pirate_mode, :boolean, default: false)
    field(:showcase, :boolean, default: false)
    field(:switch_settings_position, :boolean, default: false)
    field(:text_uppercase, :boolean, default: false)
    field(:turn_on_reminder, :boolean, default: false)
    belongs_to(:user, StreamClosedCaptionerPhoenix.Accounts.User)

    timestamps(inserted_at: :created_at)
  end

  @doc false
  def changeset(stream_settings, attrs) do
    stream_settings
    |> cast(attrs, [
      :blocklist,
      :caption_delay,
      :cc_box_size,
      :filter_profanity,
      :hide_text_on_load,
      :language,
      :pirate_mode,
      :showcase,
      :switch_settings_position,
      :text_uppercase,
      :turn_on_reminder,
      :user_id
    ])
    |> foreign_key_constraint(:user_id, name: "fk_rails_cd3c3eab8f")
    |> unique_constraint(:user_id, name: "index_stream_settings_on_user_id")
    |> validate_required([
      :language,
      :user_id,
      :caption_delay
    ])
    |> validate_number(:caption_delay, greater_than_or_equal_to: 0)
    |> validate_word_list(:blocklist)
  end

  @doc false
  def create_changeset(stream_settings, attrs) do
    stream_settings
    |> cast(attrs, [
      :language,
      :user_id,
      :hide_text_on_load,
      :text_uppercase,
      :filter_profanity,
      :cc_box_size,
      :switch_settings_position,
      :showcase,
      :pirate_mode,
      :turn_on_reminder,
      :caption_delay
    ])
    |> put_change(:language, "en-US")
    |> put_change(:caption_delay, 0)
    |> foreign_key_constraint(:user_id, name: "fk_rails_cd3c3eab8f")
    |> unique_constraint(:user_id, name: "index_stream_settings_on_user_id")
    |> validate_required([
      :language,
      :user_id,
      :caption_delay
    ])
    |> validate_number(:caption_delay, greater_than_or_equal_to: 0)
    |> validate_word_list(:blocklist)
  end

  @doc false
  def update_changeset(stream_settings, attrs) do
    stream_settings
    |> cast(attrs, [
      :blocklist,
      :caption_delay,
      :cc_box_size,
      :filter_profanity,
      :hide_text_on_load,
      :language,
      :pirate_mode,
      :showcase,
      :switch_settings_position,
      :text_uppercase,
      :turn_on_reminder
    ])
    |> validate_required([
      :language
    ])
    |> unique_constraint(:user_id, name: "index_stream_settings_on_user_id")
    |> validate_number(:caption_delay, greater_than_or_equal_to: 0)
    |> validate_word_list(:blocklist)
  end

  defp validate_word_list(changeset, field) when is_atom(field) do
    validate_change(changeset, field, fn field, value ->
      case has_valid_words?(value) do
        true ->
          []

        false ->
          [{field, "a blocklist word must contain at least one character"}]
      end
    end)
  end

  defp has_valid_words?([]), do: true

  defp has_valid_words?(list) do
    Enum.all?(list, fn word ->
      word |> String.trim() |> String.length() > 0
    end)
  end
end
