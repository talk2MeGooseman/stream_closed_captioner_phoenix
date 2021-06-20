defmodule StreamClosedCaptionerPhoenix.AccountsOauth do
  import Ecto.Query, warn: false

  alias StreamClosedCaptionerPhoenix.Accounts
  alias StreamClosedCaptionerPhoenix.Accounts.User
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

        {:ok, %{user: updated_user}}

      _ ->
        case Accounts.get_user_by_email(user_attrs["email"]) do
          %User{} ->
            {:error,
             "An existing account with the email being used by your Twitch account already exists, please log in to that accoutn and connect your Twitch account"}

          _ ->
            register_oauth_user(user_attrs, creds)
        end
    end
  end

  def find_or_register_user_with_oauth(user_attrs, creds, %User{} = current_user) do
    case get_user_for_provider("twitch", user_attrs["id"]) do
      %User{} = user when user.id != current_user.id ->
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
          {:ok, user} -> {:ok, %{user: user}}
          {:error, message} -> {:error, message}
        end
    end
  end

  defp register_oauth_user(attrs, creds) do
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
  end
end
