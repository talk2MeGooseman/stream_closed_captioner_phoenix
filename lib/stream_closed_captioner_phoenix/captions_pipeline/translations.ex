defmodule StreamClosedCaptionerPhoenix.CaptionsPipeline.Translations do
  use NewRelic.Tracer

  alias Azure.Cognitive.Translations
  alias StreamClosedCaptionerPhoenix.Accounts.User
  alias StreamClosedCaptionerPhoenix.Bits
  alias StreamClosedCaptionerPhoenix.Settings

  @trace :maybe_translate
  def maybe_translate(payload, key, %User{} = user) do
    text = Map.get(payload, key)

    # If user has their own Azure key and translation is enabled, use it directly
    if user.azure_service_key && user_translation_enabled?(user) do
      %Translations{translations: translations} = get_translations_with_user_key(user, text)
      %{payload | translations: translations}
    else
      # Use original bits-based translation logic
      if Bits.user_active_debit_exists?(user.id) do
        %Translations{translations: translations} = get_translations(user, text)
        %{payload | translations: translations}
      else
        to_languages = Settings.get_formatted_translate_languages_by_user(user.id)
        bits_balance = Bits.get_bits_balance_for_user(user)

        if Enum.empty?(to_languages) || bits_balance.balance < 500 do
          payload
        else
          activate_translations_for(user, payload, text)
        end
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

  defp get_translations_with_user_key(%User{} = user, text) do
    {:ok, stream_settings} = Settings.get_stream_settings_by_user_id(user.id)

    from_language = stream_settings.language
    # Sort so keys are always in same order for consistent hashing
    to_languages =
      Settings.get_formatted_translate_languages_by_user(user.id) |> Map.keys() |> Enum.sort()

    Azure.perform_translations(from_language, to_languages, text, user.azure_service_key)
  end

  defp user_translation_enabled?(%User{} = user) do
    case Settings.get_stream_settings_by_user_id(user.id) do
      {:ok, stream_settings} -> stream_settings.translation_enabled
      _ -> false
    end
  end
end
