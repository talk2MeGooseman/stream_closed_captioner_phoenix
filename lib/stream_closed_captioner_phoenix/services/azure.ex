defmodule Azure do
  use Nebulex.Caching

  alias StreamClosedCaptionerPhoenix.Cache

  def api_client,
    do: Application.get_env(:stream_closed_captioner_phoenix, :azure_cognitive_client)

  @decorate cacheable(
              cache: Cache,
              key: {from_language, to_languages, text},
              # Cache for 24 hours
              opts: [ttl: 86_400]
            )
  @spec perform_translations(String.t(), [String.t()], String.t()) ::
          Azure.Cognitive.Translations.t()
  def perform_translations(from_language, to_languages, text) do
    api_client().translate(from_language, to_languages, text)
  end
end
