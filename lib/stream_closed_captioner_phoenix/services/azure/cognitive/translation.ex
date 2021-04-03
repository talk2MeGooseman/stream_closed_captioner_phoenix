defmodule Azure.Cognitive.Translation do
  @type t :: %__MODULE__{
          text: String.t(),
          to: String.t()
        }

  defstruct [
    :text,
    :to
  ]

  use ExConstructor
end
