defmodule Gemini do
  def api_client,
    do: Application.get_env(:stream_closed_captioner_phoenix, :gemini_cognitive_client)

  @spec perform_translations(String.t(), [String.t()], String.t()) ::
          {:ok, Azure.Cognitive.Translations.t()} | {:error, term()}
  def perform_translations(from_language, to_languages, text) do
    api_client().translate(from_language, to_languages, text)
  end
end
