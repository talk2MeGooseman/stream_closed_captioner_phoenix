defmodule StreamClosedCaptionerPhoenix.Accounts.UserQueries do
  import Ecto.Query, warn: false

  alias StreamClosedCaptionerPhoenix.Accounts.User
  alias StreamClosedCaptionerPhoenix.Repo
  alias StreamClosedCaptionerPhoenix.Settings.StreamSettings

  def with_id(query \\ base(), id) do
    query
    |> where([user], user.id == ^id)
    |> limit(1)
  end

  def with_ids(query \\ base(), ids) do
    query
    |> where([user], user.id in ^ids)
  end

  def with_provider(query \\ base(), provider) do
    query
    |> where([user], user.provider == ^provider)
  end

  def with_uid(query \\ base(), uid) do
    query
    |> where([user], user.uid == ^uid)
    |> limit(1)
  end

  def select_id_user_pair(query \\ base()) do
    query
    |> select([user], {user.id, user})
    |> limit(1)
  end

  def with_email(query \\ base(), email) do
    query
    |> where([user], user.email == ^email)
  end

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

  defp base do
    from(_ in User, as: :user)
  end
end
