defmodule Azure.Cognitive.Translations do
  alias Azure.Cognitive.Translation

  @type t :: %__MODULE__{
          translations: list(Translation.t())
        }
  @derive Jason.Encoder
  defstruct [
    :translations
  ]

  use ExConstructor

  def new(data, args \\ []) do
    res = super(data, args)
    %{res | translations: Enum.reduce(res.translations, %{}, fn translation, acc ->
      Map.put(acc, translation["to"], Translation.new(translation))
    end)}
  end
end
