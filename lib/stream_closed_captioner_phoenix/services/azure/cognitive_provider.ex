defmodule Azure.CognitiveProvider do
  alias Azure.Cognitive.Translations

  @callback translate(String.t(), list(String.t()), String.t()) :: Translations.t()
end
