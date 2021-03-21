defmodule Azure.Cognitive.Translations do
  alias Azure.Cognitive.Translation

  @type t :: %__MODULE__{
    translations: list(Translation.t),
  }
  defstruct [
    :translations,
  ]

  use ExConstructor

  def new(data, args \\ []) do
    res = super(data, args)
    %{res | translations: Enum.map(res.translations, &Translation.new/1)}
  end
end
