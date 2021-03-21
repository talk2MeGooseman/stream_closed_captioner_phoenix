defmodule Azure do
  alias Azure.Cognitive

  @spec perform_translations([String.t], String.t) :: Azure.Cognitive.Translations.t()
  def perform_translations(languages, text) do
    Cognitive.translate(languages, text)
  end
end
