defmodule Twitch.Helix.Stream do
  defstruct [
    :game_id,
    :game_name,
    :id,
    :language,
    :started_at,
    :thumbnail_url,
    :title,
    :type,
    :user_id,
    :user_login,
    :user_name,
    :viewer_count
  ]

  use ExConstructor
end
