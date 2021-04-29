defmodule Azure.Cognitive.Translation do
  @type t :: %__MODULE__{
          text: String.t(),
          to: String.t()
        }
  @derive Jason.Encoder
  defstruct [
    :text,
    :to
  ]

  use ExConstructor
end
