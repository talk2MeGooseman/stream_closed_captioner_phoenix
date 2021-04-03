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

  @type t :: %__MODULE__{
          id: String.t(),
          login: String.t(),
          display_name: String.t(),
          type: String.t(),
          broadcaster_type: String.t(),
          description: String.t(),
          profile_image_url: String.t(),
          offline_image_url: String.t(),
          view_count: non_neg_integer(),
          email: String.t(),
          created_at: String.t()
        }
  use ExConstructor
end
