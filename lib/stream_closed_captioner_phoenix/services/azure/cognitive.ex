defmodule Azure.Cognitive do
  import Helpers

  use NewRelic.Tracer

  require Logger

  alias Azure.Cognitive.Translations
  alias Ecto.UUID
  @behaviour Azure.CognitiveProvider

  @impl Azure.CognitiveProvider

  @trace :translate
  def translate(from_language \\ "en", to_languages, text)
      when is_list(to_languages) and is_binary(text) do
    language_tuple_list =
      Enum.flat_map(to_languages, fn lang ->
        [code | _] = String.split(from_language, "-")

        if lang != code do
          [{:to, lang}]
        else
          []
        end
      end)

    params = [
      {"api-version", "3.0"},
      {:profanityAction, "Marked"},
      {:from, from_language} | language_tuple_list
    ]

    headers = [
      {"Content-Type", "application/json; charset=UTF-8"},
      {"Ocp-Apim-Subscription-Key", System.get_env("COGNITIVE_SERVICE_KEY")},
      {"Ocp-Apim-Subscription-Region", "westus2"},
      {"X-ClientTraceId", UUID.generate()}
    ]

    body =
      Jason.encode!([
        %{
          text: text
        }
      ])

    NewRelic.add_attributes(translate: %{from: from_language, to: to_languages, text: text})

    url =
      "https://api.cognitive.microsofttranslator.com/translate"
      |> encode_url_and_params(params)

    case Req.post(url, body: body, headers: headers, decode_body: false, retry: false) do
      {:ok, %{body: raw_body}} ->
        case Jason.decode(raw_body) do
          {:ok, [translations]} ->
            {:ok, Translations.new(translations)}

          {:ok, other} ->
            Logger.warning("Azure API returned unexpected JSON shape: #{inspect(other)}")
            {:error, {:unexpected_json, other}}

          {:error, reason} ->
            Logger.warning("Azure API response decode failed: #{inspect(reason)}")
            {:error, {:json_decode, reason}}
        end

      {:error, %{reason: reason}} ->
        Logger.warning("Azure API request failed: #{inspect(reason)}")
        {:error, {:http, reason}}
    end
  end
end
