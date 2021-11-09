defmodule Twitch.Helix.ExtensionChannel do
  defstruct [
    :broadcaster_id,
    :broadcaster_name,
    :game_id,
    :game_name,
    :title
  ]

  @type t :: %__MODULE__{
          game_name: String.t(),
          game_id: String.t(),
          title: String.t(),
          broadcaster_name: String.t(),
          broadcaster_id: String.t()
        }

  use ExConstructor
end
