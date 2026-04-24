defmodule Gemini.Cognitive do
  use NewRelic.Tracer

  require Logger

  alias Azure.Cognitive.Translations
  alias NewRelic.Instrumented.HTTPoison

  @behaviour Gemini.CognitiveProvider

  @model "gemini-2.5-flash-lite"
  @endpoint "https://generativelanguage.googleapis.com/v1beta/models"

  @response_schema %{
    type: "OBJECT",
    properties: %{
      translations: %{
        type: "ARRAY",
        items: %{
          type: "OBJECT",
          properties: %{
            to: %{type: "STRING"},
            text: %{type: "STRING"}
          },
          required: ["to", "text"]
        }
      }
    },
    required: ["translations"]
  }

  @impl Gemini.CognitiveProvider

  @trace :translate
  def translate(from_language \\ "en", to_languages, text)
      when is_list(to_languages) and is_binary(text) do
    [from_code | _] = String.split(from_language, "-")
    filtered_languages = Enum.reject(to_languages, &(&1 == from_code))

    if filtered_languages == [] do
      {:ok, Translations.new(%{translations: []})}
    else
      do_translate(from_language, filtered_languages, text)
    end
  end

  defp do_translate(from_language, to_languages, text) do
    NewRelic.add_attributes(translate: %{from: from_language, to: to_languages, text: text})

    headers = [
      {"Content-Type", "application/json"},
      {"x-goog-api-key", System.get_env("GEMINI_API_KEY")}
    ]

    body = Jason.encode!(build_request_body(from_language, to_languages, text))
    url = "#{endpoint()}/#{@model}:generateContent"

    case HTTPoison.post(url, body, headers) do
      {:ok, %{body: raw_body}} ->
        parse_response_body(raw_body)

      {:error, %{reason: reason}} ->
        Logger.warning("Gemini API request failed: #{inspect(reason)}")
        {:error, {:http, reason}}
    end
  end

  defp build_request_body(from_language, to_languages, text) do
    %{
      contents: [
        %{
          parts: [
            %{text: build_prompt(from_language, to_languages, text)}
          ]
        }
      ],
      generationConfig: %{
        responseMimeType: "application/json",
        responseSchema: @response_schema,
        temperature: 0
      }
    }
  end

  defp build_prompt(from_language, to_languages, text) do
    """
    Translate the text below from language code "#{from_language}" into each of these target language codes: #{Enum.join(to_languages, ", ")}.
    Respond ONLY with JSON matching the provided schema: an object with a "translations" array, where each entry is {"to": "<language code>", "text": "<translated text>"}. Include exactly one entry per target language, in the same order as the targets. Do not include any entry for the source language. Preserve punctuation and casing.

    Text:
    #{text}
    """
  end

  @doc false
  def parse_response_body(raw_body) do
    with {:ok, decoded} <- Jason.decode(raw_body),
         {:ok, inner_text} <- extract_inner_text(decoded),
         {:ok, payload} <- Jason.decode(inner_text),
         %{"translations" => translations} when is_list(translations) <- payload do
      {:ok, Translations.new(%{translations: translations})}
    else
      {:error, %Jason.DecodeError{} = reason} ->
        Logger.warning("Gemini API response decode failed: #{inspect(reason)}")
        {:error, {:json_decode, reason}}

      {:error, {:unexpected_json, _} = reason} ->
        Logger.warning("Gemini API returned unexpected JSON shape: #{inspect(reason)}")
        {:error, reason}

      other ->
        Logger.warning("Gemini API returned unexpected JSON shape: #{inspect(other)}")
        {:error, {:unexpected_json, other}}
    end
  end

  defp extract_inner_text(%{"candidates" => [candidate | _]}) do
    case get_in(candidate, ["content", "parts"]) do
      [%{"text" => text} | _] when is_binary(text) -> {:ok, text}
      _ -> {:error, {:unexpected_json, candidate}}
    end
  end

  defp extract_inner_text(other), do: {:error, {:unexpected_json, other}}

  defp endpoint,
    do: Application.get_env(:stream_closed_captioner_phoenix, :gemini_endpoint, @endpoint)
end
