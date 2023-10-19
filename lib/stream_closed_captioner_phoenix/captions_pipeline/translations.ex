defmodule StreamClosedCaptionerPhoenix.CaptionsPipeline.Translations do
  alias Azure.Cognitive.Translations
  alias StreamClosedCaptionerPhoenix.Accounts.User
  alias StreamClosedCaptionerPhoenix.{Bits, Repo, Settings}
  alias StreamClosedCaptionerPhoenix.Bits.BitsBalanceDebit

  def maybe_translate(payload, key, %User{} = user) do
    text = Map.get(payload, key)

    case Bits.get_user_active_debit(user.id) do
      %BitsBalanceDebit{} ->
        %Translations{translations: translations} = get_translations(user, text)
        %{payload | translations: translations}

      nil ->
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
    user = Repo.preload(user, :stream_settings)
    from_language = user.stream_settings.language
    # Sort so keys are always in same order for consistent hashing
    to_languages =
      Settings.get_formatted_translate_languages_by_user(user.id) |> Map.keys() |> Enum.sort()

    Azure.perform_translations(from_language, to_languages, text)
  end
end
