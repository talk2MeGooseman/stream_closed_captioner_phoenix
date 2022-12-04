defmodule Azure.Cognitive do
  import Helpers

  use NewRelic.Tracer

  alias NewRelic.Instrumented.HTTPoison
  alias Azure.Cognitive.Translations
  alias Ecto.UUID
  @behaviour Azure.CognitiveProvider

  @impl Azure.CognitiveProvider

  @trace :translate
  @spec translate(any, maybe_improper_list, binary) :: Azure.Cognitive.Translations.t()
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
      {"Content-Type", "application/json"},
      {"Ocp-Apim-Subscription-Key", System.get_env("COGNITIVE_SERVICE_KEY")},
      {"X-ClientTraceId", UUID.generate()}
    ]

    body =
      Jason.encode!([
        %{
          text: text
        }
      ])

    [translations] =
      "https://api.cognitive.microsofttranslator.com/translate"
      |> encode_url_and_params(params)
      |> HTTPoison.post!(body, headers)
      |> Map.fetch!(:body)
      |> Jason.decode!()

    Translations.new(translations)
  end
end
