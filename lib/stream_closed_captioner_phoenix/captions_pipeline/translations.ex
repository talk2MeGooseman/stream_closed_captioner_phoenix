defmodule StreamClosedCaptionerPhoenix.CaptionsPipeline.Translations do
  alias Azure.Cognitive.Translations
  alias StreamClosedCaptionerPhoenix.Accounts.User
  alias StreamClosedCaptionerPhoenix.Bits
  alias StreamClosedCaptionerPhoenix.Bits.BitsBalanceDebit
  alias StreamClosedCaptionerPhoenix.Settings

  def maybe_translate(payload, key, %User{} = user) do
    text = Map.get(payload, key)

    if Bits.user_active_debit_exists?(user.id) do
      %Translations{translations: translations} = get_translations(user, text)
      %{payload | translations: translations}
    else
      to_languages = Settings.get_formatted_translate_languages_by_user(user.id)

      if Enum.empty?(to_languages) do
        payload
      else
        activate_translations_for(user, payload, text)
      end
    end
  end

  defp activate_translations_for(%User{} = user, payload, text) do
    case Bits.activate_translations_for(user) do
      {:ok, _} ->
        translations = get_translations(user, text)
        %{payload | translations: translations}

      _ ->
        payload
    end
  end

  defp get_translations(%User{} = user, text) do
    {:ok, stream_settings} = Settings.get_stream_settings_by_user_id(user.id)

    from_language = stream_settings.language
    # Sort so keys are always in same order for consistent hashing
    to_languages =
      Settings.get_formatted_translate_languages_by_user(user.id) |> Map.keys() |> Enum.sort()

    Azure.perform_translations(from_language, to_languages, text)
  end
end
