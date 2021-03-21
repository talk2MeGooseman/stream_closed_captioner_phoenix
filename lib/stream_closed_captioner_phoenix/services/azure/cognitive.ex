defmodule Azure.Cognitive do
  import Helpers

  alias Azure.Cognitive.Translations
  alias Ecto.UUID

  @spec translate(list(String.t), String.t) :: Translations.t
  def translate(languages, text) when is_list(languages) and is_binary(text) do
    language_tuple_list = Enum.map(languages, fn lang -> {:to, lang} end)
    params = [{"api-version", "3.0"}, {:profanityAction, "Marked"} | language_tuple_list]

    headers = [
        {"Content-Type", "application/json"},
        {"Ocp-Apim-Subscription-Key", System.get_env("COGNITIVE_SERVICE_KEY")},
        {"X-ClientTraceId", UUID.generate()}
    ]

    body = Jason.encode!([%{
      text: text
    }])

    [translations] = "https://api.cognitive.microsofttranslator.com/translate"
    |> encode_url_and_params(params)
    |> HTTPoison.post!(body, headers)
    |> Map.fetch!(:body)
    |> Jason.decode!()

    Translations.new(translations)
  end
end
