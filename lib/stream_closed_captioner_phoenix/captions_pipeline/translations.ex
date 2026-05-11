defmodule StreamClosedCaptionerPhoenix.CaptionsPipeline.Translations do
  use NewRelic.Tracer

  require Logger

  alias Azure.Cognitive.Translations, as: AzureTranslations
  alias StreamClosedCaptionerPhoenix.Accounts.User
  alias StreamClosedCaptionerPhoenix.Bits
  alias StreamClosedCaptionerPhoenix.Settings

  @trace :maybe_translate
  def maybe_translate(payload, key, %User{} = user) do
    provider = if FunWithFlags.enabled?(:gemini_translations, for: user), do: :gemini, else: :azure
    text = Map.get(payload, key)

    metadata = %{
      user_id: user.id,
      provider: provider,
      from_lang: nil,
      to_langs: [],
      to_count: 0,
      result: nil,
      error_reason: nil
    }

    :telemetry.span([:scc, :captions, :translation], metadata, fn ->
      {payload_out, result_meta} = do_maybe_translate(payload, text, user, provider)
      {payload_out, Map.merge(metadata, result_meta)}
    end)
  end

  defp do_maybe_translate(payload, text, %User{} = user, provider) do
    cond do
      Bits.user_active_debit_exists?(user.id) ->
        perform_translation(payload, text, user, provider)

      true ->
        to_languages = Settings.get_formatted_translate_languages_by_user(user.id)
        bits_balance = Bits.get_bits_balance_for_user(user)

        cond do
          Enum.empty?(to_languages) ->
            {payload, %{result: :skipped_no_languages}}

          bits_balance.balance < 500 ->
            {payload, %{result: :skipped_no_balance}}

          true ->
            activate_then_translate(payload, text, user, provider)
        end
    end
  end

  defp activate_then_translate(payload, text, user, provider) do
    case Bits.activate_translations_for(user) do
      {:ok, _} ->
        :telemetry.execute(
          [:scc, :captions, :translation, :bits_debit],
          %{count: 1},
          %{user_id: user.id}
        )

        perform_translation(payload, text, user, provider)

      other ->
        {payload, %{result: :error, error_reason: inspect(other)}}
    end
  end

  defp perform_translation(payload, text, user, provider) do
    case get_translations(user, text, provider) do
      {:ok, %AzureTranslations{translations: translations}} ->
        {%{payload | translations: translations},
         %{result: :ok, to_count: map_size(translations)}}

      {:error, reason} ->
        Logger.warning("translation failed", user_id: user.id, reason: inspect(reason))
        {payload, %{result: :error, error_reason: inspect(reason)}}
    end
  end

  defp get_translations(%User{} = user, text, provider) do
    {:ok, stream_settings} = Settings.get_stream_settings_by_user_id(user.id)

    from_language = stream_settings.language
    # Sort so keys are always in same order for consistent hashing
    to_languages =
      Settings.get_formatted_translate_languages_by_user(user.id) |> Map.keys() |> Enum.sort()

    case provider do
      :gemini -> Gemini.perform_translations(from_language, to_languages, text)
      :azure -> Azure.perform_translations(from_language, to_languages, text)
    end
  end
end
