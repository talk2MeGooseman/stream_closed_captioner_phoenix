defmodule Azure do
  def api_client,
    do: Application.get_env(:stream_closed_captioner_phoenix, :azure_cognitive_client)

  @spec perform_translations(String.t(), [String.t()], String.t()) ::
          Azure.Cognitive.Translations.t()
  def perform_translations(from_language, to_languages, text) do
    api_client().translate(from_language, to_languages, text)
  end
end
