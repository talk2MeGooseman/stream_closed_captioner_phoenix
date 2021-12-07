defmodule Twitch.Helix.EventSub do
  defstruct [
    :condition,
    :cost,
    :created_at,
    :id,
    :status,
    :transport,
    :type,
    :version
  ]

  @type t :: %__MODULE__{
          condition: map(),
          cost: integer(),
          created_at: String.t(),
          id: String.t(),
          status: String.t(),
          transport: map(),
          type: String.t(),
          version: String.t()
        }
  use ExConstructor
end
