defmodule Twitch.Extension.Channel do
  defstruct [
    :game,
    :id,
    :title,
    :username,
    :view_count
  ]

  use ExConstructor
end
