defmodule Azure.Cognitive do
  import Helpers

  use NewRelic.Tracer

  alias Azure.Cognitive.Translations
  alias Ecto.UUID
  alias NewRelic.Instrumented.HTTPoison
  @behaviour Azure.CognitiveProvider

  @impl Azure.CognitiveProvider

  @trace :translate
  def translate(from_language \\ "en", to_languages, text)
      when is_list(to_languages) and is_binary(text) do
    translate(from_language, to_languages, text, nil)
  end

  @impl Azure.CognitiveProvider

  @trace :translate
  def translate(from_language, to_languages, text, user_key)
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

    api_key = user_key || System.get_env("COGNITIVE_SERVICE_KEY")

    headers = [
      {"Content-Type", "application/json; charset=UTF-8"},
      {"Ocp-Apim-Subscription-Key", api_key},
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

    [translations] =
      "https://guzman.codes/azure_proxy/translate"
      |> encode_url_and_params(params)
      |> HTTPoison.post!(body, headers)
      |> Map.fetch!(:body)
      |> Jason.decode!()

    Translations.new(translations)
  end
end
