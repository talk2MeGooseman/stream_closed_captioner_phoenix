defmodule StreamClosedCaptionerPhoenix.AccountsOauth do
  import Ecto.Query, warn: false

  alias StreamClosedCaptionerPhoenix.Accounts
  alias StreamClosedCaptionerPhoenix.Accounts.User
  alias StreamClosedCaptionerPhoenix.Repo
  alias StreamClosedCaptionerPhoenix.Settings


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

  def find_or_register_user_with_oauth(attrs, current_user) when is_nil(current_user) do
    case get_user_for_provider("twitch", attrs["id"]) do
      %User{} = user ->
        {:ok, updated_user} =
          Accounts.User.oauth_update_changeset(user, %{
            email: attrs["email"],
            username: attrs["display_name"],
            profile_image_url: attrs["profile_image_url"],
            login: attrs["login"],
            description: attrs["description"],
            offline_image_url: attrs["offline_image_url"]
          })
          |> Repo.update()

        {:ok, %{user: updated_user}}

      _ ->
        case Accounts.get_user_by_email(attrs["email"]) do
          %User{} ->
            {:error,
             "An existing account with the email being used by your Twitch account already exists, please log in to that accoutn and connect your Twitch account"}

          _ ->
            register_oauth_user(attrs)
        end
    end
  end

  def find_or_register_user_with_oauth(attrs, %User{} = current_user) do
    case get_user_for_provider("twitch", attrs["id"]) do
      %User{} = user when user.id != current_user.id ->
        {:error, "Your Twitch account is connected to another account, please log out and log in with Twitch to remove the connection from your other account."}

      _ ->
        User.oauth_update_changeset(current_user, %{
          email: attrs["email"],
          provider: "twitch",
          username: attrs["display_name"],
          profile_image_url: attrs["profile_image_url"],
          login: attrs["login"],
          description: attrs["description"],
          offline_image_url: attrs["offline_image_url"],
          uid: attrs["id"]
        })
        |> Repo.update()
    end
  end

  defp register_oauth_user(attrs \\ %{}) do
    Ecto.Multi.new()
    |> Ecto.Multi.run(:user, fn _repo, _changes ->
      Accounts.register_user(%{
        email: attrs["email"],
        password: Accounts.generate_secure_password(),
        uid: attrs["id"],
        username: attrs["display_name"],
        profile_image_url: attrs["profile_image_url"],
        login: attrs["login"],
        description: attrs["description"],
        offline_image_url: attrs["offline_image_url"],
        provider: "twitch"
      })
    end)
    |> Ecto.Multi.run(:stream_setings, fn _repo, %{user: user} ->
      Settings.create_stream_settings(user)
    end)
    |> Repo.transaction()
  end
end
