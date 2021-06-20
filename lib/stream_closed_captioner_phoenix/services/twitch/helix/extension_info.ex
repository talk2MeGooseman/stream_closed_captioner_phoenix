defmodule Twitch.Helix.ExtensionInfo do
  defstruct [
    :active,
    :id,
    :name,
    :version
  ]

  @type t :: %__MODULE__{
          active: Boolean.t(),
          id: String.t(),
          name: String.t(),
          version: String.t()
        }

  use ExConstructor
end
