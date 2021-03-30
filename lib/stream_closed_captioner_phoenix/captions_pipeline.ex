defmodule StreamClosedCaptionerPhoenix.CaptionsPipeline do
  alias Azure.Cognitive.Translations
  alias StreamClosedCaptionerPhoenix.Accounts.User
  alias StreamClosedCaptionerPhoenix.{Bits, Repo, Settings}
  alias StreamClosedCaptionerPhoenix.Bits.BitsBalanceDebit
  alias StreamClosedCaptionerPhoenix.CaptionsPipeline.Profanity
  alias Twitch.Extension.CaptionsPayload

  def pipeline_to(:zoom, %User{} = user, message) do
    user = Repo.preload(user, :stream_settings)

    params = %Zoom.Params{
      seq: Map.get(message, :seq),
      lang: user.stream_settings.language
    }

    url = Map.get(message, :url)
    text = maybe_censor_message_for(user, message) |> Map.get(:final)
    Zoom.send_captions_to(url, text, params)
  end

  def pipeline_to(:twitch, %User{} = user, message) do
    user = Repo.preload(user, :stream_settings)

    payload = CaptionsPayload.new(message)
    payload = Map.merge(payload, maybe_censor_message_for(user, payload))

    payload =
      case maybe_translate(user, Map.get(payload, :interim)) do
        %Translations{} = translations ->
          Map.merge(
            payload,
            translations
          )

        nil ->
          payload
      end

    case Twitch.send_pubsub_message(user.uid, payload) do
      {:ok, _} ->
        IO.puts("Message sent successfully")
        {:ok, payload}

      {:error, message} ->
        IO.puts("Error occurred: #{message}")
        :error
    end
  end

  defp maybe_censor_message_for(%User{} = user, message) do
    message
    |> Map.put(
      :interim,
      Profanity.maybe_censor_for(user.stream_settings, Map.get(message, :interim))
    )
    |> Map.put(
      :final,
      Profanity.maybe_censor_for(user.stream_settings, Map.get(message, :final))
    )
  end

  @spec maybe_translate(
          %StreamClosedCaptionerPhoenix.Accounts.User{:id => any},
          String.t()
        ) :: nil | Azure.Cognitive.Translations.t()
  defp maybe_translate(%User{} = user, text) when is_binary(text) do
    case Bits.get_user_active_debit(user.id) do
      %BitsBalanceDebit{} ->
        get_translations(user, text)

      nil ->
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
end
