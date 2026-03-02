defmodule Azure.Cognitive.Translation do
  @type t :: %__MODULE__{
          text: String.t(),
          name: String.t()
        }
  @derive Jason.Encoder
  defstruct [
    :text,
    :name
  ]

  use ExConstructor

  def new(data, args \\ []) do
    res = super(data, args)
    name = StreamClosedCaptionerPhoenix.Settings.translatable_languages()[data["to"]]
    %{res | name: name}
  end
end
