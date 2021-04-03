defmodule Azure.CognitiveProvider do
  alias Azure.Cognitive.Translations
  alias Ecto.UUID

  @callback translate(String.t(), list(String.t()), String.t()) :: Translations.t()
end
