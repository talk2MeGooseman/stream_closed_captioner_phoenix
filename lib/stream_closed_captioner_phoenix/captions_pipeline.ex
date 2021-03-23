defmodule StreamClosedCaptionerPhoenix.CaptionsPipeline do
  alias StreamClosedCaptionerPhoenix.Accounts.User
  alias StreamClosedCaptionerPhoenix.Bits
  alias StreamClosedCaptionerPhoenix.Bits.BitsBalanceDebit
  alias StreamClosedCaptionerPhoenix.CaptionsPipeline.Profanity
  alias StreamClosedCaptionerPhoenix.Settings
  alias StreamClosedCaptionerPhoenix.Settings.StreamSettings

  @spec process_text(String.t(), User.t()) :: String.t()
  def process_text(text, %StreamSettings{} = stream_settings) do
    Profanity.maybe_censor_for(stream_settings, text)
    # TODO Need to add async job to store captions for history
  end

  @spec maybe_translate(
          %StreamClosedCaptionerPhoenix.Accounts.User{:id => any},
          String.t()
        ) :: nil | Azure.Cognitive.Translations.t()
  def maybe_translate(%User{} = user, text) when is_binary(text) do
    case Bits.get_user_active_debit(user.id) do
      %BitsBalanceDebit{} ->
        get_translations(user, text)

      _ ->
        case Bits.activate_translations_for(user) do
          {:ok, _} -> get_translations(user, text)
          _ -> nil
        end
    end
  end

  defp get_translations(%User{} = user, text) do
    user = StreamClosedCaptionerPhoenix.Repo.preload(user, :stream_settings)
    from_language = user.stream_settings.language
    to_languages = Settings.get_formatted_translate_languages_by_user(user.id) |> Map.keys()

    Azure.perform_translations(from_language, to_languages, text)
  end

  # def defp twitch_connected?(%User{provider: provider, uid: uid}), do: provider == "twitch" and is_binary(uid)
end
