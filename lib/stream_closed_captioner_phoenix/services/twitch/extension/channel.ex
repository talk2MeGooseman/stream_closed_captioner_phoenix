defmodule Twitch.Extension.Channel do
  defstruct [
    :game,
    :id,
    :title,
    :username,
    :view_count
  ]

  @type t :: %__MODULE__{
          game: String.t(),
          id: String.t(),
          title: String.t(),
          username: String.t(),
          view_count: integer()
        }

  use ExConstructor
end
