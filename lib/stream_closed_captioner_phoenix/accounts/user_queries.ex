defmodule StreamClosedCaptionerPhoenix.Accounts.UserQueries do
  import Ecto.Query, warn: false

  alias StreamClosedCaptionerPhoenix.Accounts.User
  alias StreamClosedCaptionerPhoenix.Settings.StreamSettings
  alias StreamClosedCaptionerPhoenix.Repo

  def query_users_with_settings() do
    query =
      from(u in User,
        join: ss in StreamSettings,
        on: ss.user_id == u.id,
        select: %{id: u.id}
      )

    query
  end

  def get_users_without_settings() do
    query =
      from(u in User,
        left_join: ss in StreamSettings,
        on: ss.user_id == u.id,
        where: is_nil(ss.user_id),
        select: u.id
      )

    Repo.all(query)
  end
end
