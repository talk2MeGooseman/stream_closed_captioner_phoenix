defmodule Zoom.Params do
  @type t :: %__MODULE__{
          seq: non_neg_integer() | nil,
          lang: String.t() | nil
        }
  defstruct [:seq, :lang]

  use ExConstructor
end
