defmodule StreamClosedCaptionerPhoenix.AccountsOauth do
  use Nebulex.Caching

  import Ecto.Query, warn: false

  alias StreamClosedCaptionerPhoenix.Accounts
  alias StreamClosedCaptionerPhoenix.Accounts.User
  alias StreamClosedCaptionerPhoenix.AuditLog
  alias StreamClosedCaptionerPhoenix.Cache
  alias StreamClosedCaptionerPhoenix.Repo

  @doc """
  Gets a user by their provider and uid

  Return nil fo user doesnt exist

  ## Examples

      iex> get_user_by_channel_id("twitch", 123)
      %User{}

      iex> get_user_by_channel_id("twitch", 457)
      nil

  """
  @decorate cacheable(
              cache: Cache,
              key: {User, uid}
            )
  def get_user_for_provider(provider, uid) do
    User
    |> where(uid: ^uid)
    |> where(provider: ^provider)
    |> Repo.one()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user's provider.

  ## Examples

      iex> change_user_provider(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_provider(user, attrs \\ %{}) do
    User.provider_changeset(user, attrs)
  end

  def find_or_register_user_with_oauth(user_attrs, creds, current_user)
      when is_nil(current_user) do
    case get_user_for_provider("twitch", user_attrs["id"]) do
      %User{} = user ->
        {:ok, updated_user} =
          Accounts.User.oauth_update_changeset(user, %{
            email: user_attrs["email"],
            username: user_attrs["display_name"],
            profile_image_url: user_attrs["profile_image_url"],
            login: user_attrs["login"],
            description: user_attrs["description"],
            offline_image_url: user_attrs["offline_image_url"],
            access_token: creds[:token],
            refresh_token: creds[:refresh_token]
          })
          |> Repo.update()

        AuditLog.info("oauth.account_refreshed", %{user_id: updated_user.id, provider: "twitch"})

        {:ok, %{user: updated_user}}

      _ ->
        case Accounts.get_user_by_email(user_attrs["email"]) do
          %User{} = existing_user ->
            AuditLog.warn("oauth.account_link_failed_email_conflict", %{
              user_id: existing_user.id,
              provider: "twitch"
            })

            {:error,
             "An existing account with the email being used by your Twitch account already exists, please log in to that account and connect your Twitch account"}

          _ ->
            register_oauth_user(user_attrs, creds)
        end
    end
  end

  def find_or_register_user_with_oauth(user_attrs, creds, %User{} = current_user) do
    case get_user_for_provider("twitch", user_attrs["id"]) do
      %User{} = user when user.id != current_user.id ->
        AuditLog.warn("oauth.account_link_failed_already_linked", %{
          user_id: current_user.id,
          provider: "twitch"
        })

        {:error,
         "Your Twitch account is connected to another account, please log out and log in with Twitch to remove the connection from your other account."}

      _ ->
        User.oauth_update_changeset(current_user, %{
          email: user_attrs["email"],
          provider: "twitch",
          username: user_attrs["display_name"],
          profile_image_url: user_attrs["profile_image_url"],
          login: user_attrs["login"],
          description: user_attrs["description"],
          offline_image_url: user_attrs["offline_image_url"],
          uid: user_attrs["id"],
          access_token: creds[:access_token],
          refresh_token: creds[:refresh_token]
        })
        |> Repo.update()
        |> case do
          {:ok, user} ->
            AuditLog.info("oauth.account_linked", %{user_id: user.id, provider: "twitch"})
            {:ok, %{user: user}}

          {:error, message} ->
            AuditLog.warn("oauth.account_link_failed", %{
              user_id: current_user.id,
              provider: "twitch"
            })

            {:error, message}
        end
    end
  end

  defp register_oauth_user(attrs, creds) do
    result =
      Accounts.register_user(%{
        email: attrs["email"],
        password: Accounts.generate_secure_password(),
        uid: attrs["id"],
        username: attrs["display_name"],
        profile_image_url: attrs["profile_image_url"],
        login: attrs["login"],
        description: attrs["description"],
        offline_image_url: attrs["offline_image_url"],
        provider: "twitch",
        access_token: creds[:access_token],
        refresh_token: creds[:refresh_token]
      })

    case result do
      {:ok, %{user: user}} ->
        AuditLog.info("oauth.account_registered", %{user_id: user.id, provider: "twitch"})

      {:error, _, _changeset, _} ->
        AuditLog.warn("oauth.account_register_failed", %{provider: "twitch"})
    end

    result
  end
end
