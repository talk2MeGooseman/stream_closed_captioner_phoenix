defmodule Twitch.Helix.User do
  defstruct [
    :id,
    :login,
    :display_name,
    :type,
    :broadcaster_type,
    :description,
    :profile_image_url,
    :offline_image_url,
    :view_count,
    :email,
    :created_at
  ]

  use ExConstructor
end
