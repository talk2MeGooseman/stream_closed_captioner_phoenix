defmodule StreamClosedCaptionerPhoenix.CaptionsPipeline.Translations do
  use NewRelic.Tracer

  require Logger

  alias Azure.Cognitive.Translations
  alias StreamClosedCaptionerPhoenix.Accounts.User
  alias StreamClosedCaptionerPhoenix.Bits
  alias StreamClosedCaptionerPhoenix.Settings

  @trace :maybe_translate
  def maybe_translate(payload, key, %User{} = user) do
    text = Map.get(payload, key)

    # Interim frames carry an empty `:final`; translating blank text just burns an API
    # call and returns an empty `translations` map that wipes the displayed translation on
    # the client. Skip it and leave `translations` untouched (nil).
    if blank?(text) do
      payload
    else
      do_maybe_translate(payload, text, user)
    end
  end

  defp do_maybe_translate(payload, text, %User{} = user) do
    if Bits.user_active_debit_exists?(user.id) do
      case get_translations(user, text) do
        {:ok, %Translations{translations: translations}} ->
          %{payload | translations: translations}

        {:error, reason} ->
          Logger.warning("Translation failed for user #{user.id}: #{inspect(reason)}")
          %{payload | translation_error: :failed}
      end
    else
      to_languages = Settings.get_formatted_translate_languages_by_user(user.id)
      bits_balance = Bits.get_bits_balance_for_user(user)

      if Enum.empty?(to_languages) || !sufficient_balance?(bits_balance) do
        payload
      else
        activate_translations_for(user, payload, text)
      end
    end
  end

  defp activate_translations_for(%User{} = user, payload, text) do
    case Bits.activate_translations_for(user) do
      {:ok, _} ->
        case get_translations(user, text) do
          {:ok, %Translations{translations: translations}} ->
            %{payload | translations: translations}

          {:error, reason} ->
            Logger.warning(
              "Translation failed after activation for user #{user.id}: #{inspect(reason)}"
            )

            %{payload | translation_error: :failed}
        end

      _ ->
        payload
    end
  end

  # A user who has never purchased bits has no BitsBalance row, so the lookup returns nil.
  # Treat that as insufficient funds rather than dereferencing nil.
  defp sufficient_balance?(nil), do: false
  defp sufficient_balance?(%{balance: balance}), do: balance >= 500

  defp blank?(nil), do: true
  defp blank?(text) when is_binary(text), do: String.trim(text) == ""
  defp blank?(_), do: true

  defp get_translations(%User{} = user, text) do
    {:ok, stream_settings} = Settings.get_stream_settings_by_user_id(user.id)

    from_language = stream_settings.language
    # Sort so keys are always in same order for consistent hashing
    to_languages =
      Settings.get_formatted_translate_languages_by_user(user.id) |> Map.keys() |> Enum.sort()

    if FunWithFlags.enabled?(:gemini_translations, for: user) do
      Gemini.perform_translations(from_language, to_languages, text)
    else
      Azure.perform_translations(from_language, to_languages, text)
    end
  end
end
