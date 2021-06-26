defmodule Azure.CognitiveProvider do
  alias Azure.Cognitive.Translations

  @callback translate(String.t(), [String.t()], String.t()) :: Translations.t()
end
