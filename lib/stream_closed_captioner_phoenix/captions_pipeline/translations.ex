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
    # Sort so keys are always in same order for consistent hashing
    to_languages =
      Settings.get_formatted_translate_languages_by_user(user.id) |> Map.keys() |> Enum.sort()

    # Hash spoken text and languages to make unique bucket, encode to reduce size of key
    key = :crypto.hash(:md5, text <> to_string(to_languages)) |> Base.encode32()

    {_, translations} =
      Cachex.fetch(:translation_cache, key, fn _key ->
        IO.puts("Load Cache")
        translations = Azure.perform_translations(from_language, to_languages, text)
        {:commit, translations}
      end)

    Cachex.expire(:my_cache, key, :timer.minutes(60))

    translations
  end
end
