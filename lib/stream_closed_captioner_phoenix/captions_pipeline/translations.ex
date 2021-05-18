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
        case Bits.activate_translations_for(user) do
          {:ok, _} ->
            %Translations{translations: translations} = get_translations(user, text)
            %{payload | translations: translations}

          _ ->
            payload
        end
    end
  end

  defp get_translations(%User{} = user, text) do
    user = Repo.preload(user, :stream_settings)
    from_language = user.stream_settings.language
    to_languages = Settings.get_formatted_translate_languages_by_user(user.id) |> Map.keys()

    Azure.perform_translations(from_language, to_languages, text)
  end
end
