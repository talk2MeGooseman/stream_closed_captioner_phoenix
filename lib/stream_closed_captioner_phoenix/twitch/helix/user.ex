defmodule Twitch.Helix.User do
  defstruct [
    :id,
    :user_id,
    :user_name,
    :game_id,
    :game_name,
    :type,
    :title,
    :viewer_count,
    :started_at,
    :language,
    :thumbnail_url
  ]

  use ExConstructor
end
