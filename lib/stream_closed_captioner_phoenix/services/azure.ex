defmodule Azure do
  use Nebulex.Caching

  def api_client,
    do: Application.get_env(:stream_closed_captioner_phoenix, :azure_cognitive_client)

  @spec perform_translations(String.t(), [String.t()], String.t()) ::
          Azure.Cognitive.Translations.t()
  def perform_translations(from_language, to_languages, text) do
    api_client().translate(from_language, to_languages, text)
  end

  @spec perform_translations(String.t(), [String.t()], String.t(), String.t() | nil) ::
          Azure.Cognitive.Translations.t()
  def perform_translations(from_language, to_languages, text, user_key) do
    api_client().translate(from_language, to_languages, text, user_key)
  end
end
