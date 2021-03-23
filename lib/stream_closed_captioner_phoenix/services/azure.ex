defmodule Azure do
  alias Azure.Cognitive

  @spec perform_translations(String.t(), [String.t()], String.t()) ::
          Azure.Cognitive.Translations.t()
  def perform_translations(from_language, to_languages, text) do
    Cognitive.translate(from_language, to_languages, text)
  end
end
