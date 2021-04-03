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

  @type t :: %__MODULE__{
          game_id: String.t(),
          game_name: String.t(),
          id: String.t(),
          language: String.t(),
          started_at: String.t(),
          thumbnail_url: String.t(),
          title: String.t(),
          type: String.t(),
          user_id: String.t(),
          user_login: String.t(),
          user_name: String.t(),
          viewer_count: String.t()
        }

  use ExConstructor
end
