defmodule Azure.Cognitive do
  require Logger
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

    url =
      "https://guzman.codes/azure_proxy/translate"
      |> encode_url_and_params(params)

    # SECURITY: Use post (not post!) to handle errors without exposing keys
    case HTTPoison.post(url, body, headers) do
      {:ok, %{status_code: 200, body: response_body}} ->
        [translations] = Jason.decode!(response_body)
        Translations.new(translations)

      {:ok, %{status_code: status_code}} ->
        # Log error without exposing sensitive data
        Logger.warning("Azure translation API returned error status",
          status_code: status_code,
          user_provided_key: !is_nil(user_key)
        )

        Translations.new(%{"translations" => []})

      {:error, %HTTPoison.Error{reason: reason}} ->
        # Scrub any potential key data from error messages
        safe_reason = scrub_sensitive_data(reason)

        Logger.error("Azure translation API error",
          reason: safe_reason,
          user_provided_key: !is_nil(user_key)
        )

        Translations.new(%{"translations" => []})
    end
  rescue
    exception ->
      # CRITICAL: Scrub exception to prevent key leakage in error tracking
      Logger.error("Translation exception occurred",
        exception_type: exception.__struct__,
        user_provided_key: !is_nil(user_key)
      )

      Translations.new(%{"translations" => []})
  end

  # Scrub potential API keys from error messages
  defp scrub_sensitive_data(data) when is_binary(data) do
    data
    |> String.replace(~r/[a-f0-9]{32,}/, "[REDACTED_KEY]")
    |> String.replace(~r/Ocp-Apim-Subscription-Key[^,\}]+/, "Ocp-Apim-Subscription-Key: [REDACTED]")
  end

  defp scrub_sensitive_data(data), do: inspect(data)
end
