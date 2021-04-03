defmodule Twitch.Helix.Cost do
  defstruct [
    :amount,
    :type
  ]

  @type t :: %__MODULE__{
          amount: non_neg_integer(),
          type: String.t()
        }
  use ExConstructor
end
