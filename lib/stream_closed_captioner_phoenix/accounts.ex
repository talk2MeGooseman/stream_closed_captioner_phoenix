defmodule StreamClosedCaptionerPhoenix.Accounts do
  @moduledoc """
  The Accounts context.
  """
  use Nebulex.Caching

  import Ecto.Query, warn: false
  alias StreamClosedCaptionerPhoenix.Cache
  alias StreamClosedCaptionerPhoenix.Repo

  alias StreamClosedCaptionerPhoenix.Accounts.{
    EventsubSubscription,
    EventsubSubscriptionQueries,
    User,
    UserNotifier,
    UserToken,
    UserQueries
  }

  alias StreamClosedCaptionerPhoenix.Bits
  alias StreamClosedCaptionerPhoenix.Settings

  def owner_id, do: "120750024"

  @doc """
  Returns boolean if user is admin

  ## Examples

      iex> is_admin?("120750024")
      true

      iex> is_admin?("123")
      false

  """
  def is_admin?(nil), do: false

  def is_admin?(user) do
    user.uid == "120750024"
  end

  ## Database getters

  @doc """
  Gets a user by email.

  ## Examples

      iex> get_user_by_email("foo@example.com")
      %User{}

      iex> get_user_by_email("unknown@example.com")
      nil

  """
  def get_user_by_email(nil), do: nil

  def get_user_by_email(email) when is_binary(email) do
    String.downcase(email)
    |> UserQueries.with_email()
    |> Repo.one()
  end

  @doc """
  Gets a user by email and password.

  ## Examples

      iex> get_user_by_email_and_password("foo@example.com", "correct_password")
      %User{}

      iex> get_user_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = get_user_by_email(email)
    if User.valid_password?(user, password), do: user
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: UserQueries.with_id(id) |> Repo.one!()

  @doc """
  Gets a single user by their provider and uid.

  Return nil if no user is found.

  ## Examples

      iex> get_user_by_provider_uid(12342398)
      %User{}

      iex> get_user_by_provider_uid(0000)
      nil

  """
  def get_user_by_provider_uid(provider \\ "twitch", uid) do
    UserQueries.with_provider(provider)
    |> UserQueries.with_uid(uid)
    |> Repo.one()
  end

  def get_users_map(ids) do
    UserQueries.with_ids(ids)
    |> UserQueries.select_id_user_pair()
    |> Repo.all()
    |> Enum.into(%{})
  end

  @doc """
  Returns true if the user has the extension enabled.

  ## Examples
      iex> user_has_extension_installed?(user)
      true
  """
  def user_has_extension_installed?(%User{} = user) do
    try do
      result = Twitch.get_users_active_extensions(user)

      check_for_extension_in(result, "overlay") || check_for_extension_in(result, "panel") ||
        check_for_extension_in(result, "component")
    rescue
      _ -> true
    end
  end

  defp check_for_extension_in(result, key) do
    result
    |> Map.get(key)
    |> Map.values()
    |> Enum.any?(fn ext -> ext["id"] == Twitch.extension_id() end)
  end

  @doc """
  Registers a user.

  ## Examples

      iex> register_user(%{field: value})
      {:ok, %User{}}

      iex> register_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_user(attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.run(:user, fn _repo, _changes ->
      %User{}
      |> User.registration_changeset(attrs)
      |> Repo.insert()
    end)
    |> Ecto.Multi.run(:stream_settings, fn _repo, %{user: user} ->
      Settings.create_stream_settings(user)
    end)
    |> Ecto.Multi.run(:bits_balance, fn _repo, %{user: user} ->
      Bits.create_bits_balance(user)
    end)
    |> Repo.transaction()
  end

  @doc """
  Delete a user.

  ## Examples

      iex> delete_user(%User{})
      {:ok, %User{}}

      iex> delete_user(%User{})
      {:error, %Ecto.Changeset{}}

  """
  @decorate cache_evict(
              cache: Cache,
              key: {User, user.uid}
            )
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user_registration(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_registration(%User{} = user, attrs \\ %{}) do
    User.registration_changeset(user, attrs, hash_password: false)
  end

  ## Settings

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user email.

  ## Examples

      iex> change_user_email(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_email(user, attrs \\ %{}) do
    User.email_changeset(user, attrs)
  end

  @doc """
  Emulates that the email will change without actually changing
  it in the database.

  ## Examples

      iex> apply_user_email(user, "valid password", %{email: ...})
      {:ok, %User{}}

      iex> apply_user_email(user, "invalid password", %{email: ...})
      {:error, %Ecto.Changeset{}}

  """
  def apply_user_email(user, password, attrs) do
    user
    |> User.email_changeset(attrs)
    |> User.validate_current_password(password)
    |> Ecto.Changeset.apply_action(:update)
  end

  @doc """
  Remove the provider information for a given user.

  ## Examples

      iex> remove_user_provider(user)
      {:ok, %User{}}

      iex> remove_user_provider(user)
      {:error, %Ecto.Changeset{}}

  """
  def remove_user_provider(%User{} = user) do
    user
    |> User.remove_provider(%{})
    |> Repo.update()
  end

  @doc """
  Updates the user email using the given token.

  If the token matches, the user email is updated and the token is deleted.
  The confirmed_at date is also updated to the current time.
  """
  def update_user_email(user, token) do
    context = "change:#{user.email}"

    with {:ok, query} <- UserToken.verify_change_email_token_query(token, context),
         %UserToken{sent_to: email} <- Repo.one(query),
         {:ok, _} <- Repo.transaction(user_email_multi(user, email, context)) do
      :ok
    else
      _ -> :error
    end
  end

  defp user_email_multi(user, email, context) do
    changeset = user |> User.email_changeset(%{email: email})

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, [context]))
  end

  @doc """
  Delivers the update email instructions to the given user.

  ## Examples

      iex> deliver_update_email_instructions(user, current_email, &Routes.user_update_email_url(conn, :edit, &1))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_update_email_instructions(%User{} = user, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "change:#{current_email}")

    Repo.insert!(user_token)
    UserNotifier.deliver_update_email_instructions(user, update_email_url_fun.(encoded_token))
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user password.

  ## Examples

      iex> change_user_password(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_password(user, attrs \\ %{}) do
    User.password_changeset(user, attrs, hash_password: false)
  end

  @doc """
  Updates the user password.

  ## Examples

      iex> update_user_password(user, "valid password", %{password: ...})
      {:ok, %User{}}

      iex> update_user_password(user, "invalid password", %{password: ...})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_password(user, password, attrs) do
    changeset =
      user
      |> User.password_changeset(attrs)
      |> User.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  @doc """
  Gets the user with the given signed token.
  """
  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_session_token(token) do
    Repo.delete_all(UserToken.token_and_context_query(token, "session"))
    :ok
  end

  ## Confirmation

  @doc """
  Delivers the confirmation email instructions to the given user.

  ## Examples

      iex> deliver_user_confirmation_instructions(user, &Routes.user_confirmation_url(conn, :confirm, &1))
      {:ok, %{to: ..., body: ...}}

      iex> deliver_user_confirmation_instructions(confirmed_user, &Routes.user_confirmation_url(conn, :confirm, &1))
      {:error, :already_confirmed}

  """
  def deliver_user_confirmation_instructions(%User{} = user, confirmation_url_fun)
      when is_function(confirmation_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "confirm")
    Repo.insert!(user_token)
    UserNotifier.deliver_confirmation_instructions(user, confirmation_url_fun.(encoded_token))
  end

  @doc """
  Confirms a user by the given token.

  If the token matches, the user account is marked as confirmed
  and the token is deleted.
  """
  def confirm_user(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "confirm"),
         %User{} = user <- Repo.one(query),
         {:ok, _} <- Repo.transaction(confirm_user_multi(user)) do
      {:ok, user}
    else
      _ -> :error
    end
  end

  defp confirm_user_multi(user) do
    Ecto.Multi.new()
    |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, ["confirm"]))
  end

  ## Reset password

  @doc """
  Delivers the reset password email to the given user.

  ## Examples

      iex> deliver_user_reset_password_instructions(user, &Routes.user_reset_password_url(conn, :edit, &1))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_user_reset_password_instructions(%User{} = user, reset_password_url_fun)
      when is_function(reset_password_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "reset_password")
    Repo.insert!(user_token)
    UserNotifier.deliver_reset_password_instructions(user, reset_password_url_fun.(encoded_token))
  end

  @doc """
  Gets the user by reset password token.

  ## Examples

      iex> get_user_by_reset_password_token("validtoken")
      %User{}

      iex> get_user_by_reset_password_token("invalidtoken")
      nil

  """
  def get_user_by_reset_password_token(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "reset_password"),
         %User{} = user <- Repo.one(query) do
      user
    else
      _ -> nil
    end
  end

  @doc """
  Resets the user password.

  ## Examples

      iex> reset_user_password(user, %{password: "new long password", password_confirmation: "new long password"})
      {:ok, %User{}}

      iex> reset_user_password(user, %{password: "valid", password_confirmation: "not the same"})
      {:error, %Ecto.Changeset{}}

  """
  def reset_user_password(user, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.password_changeset(user, attrs))
    |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  @doc """
  Returns a randomly generated password.

  ## Examples

      iex> generate_secure_password()
      "rm/JfqH8Y+Jd7m5SHTHJoA=="

  """
  def generate_secure_password do
    SecureRandom.base64()
  end

  @doc """
  Creates a new eventsub_subscription record.

  ## Examples

      iex> create_eventsub_subscription(user, %{field: value})
      {:ok, %EventsubScription{}}

      iex> create_eventsub_subscription(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_eventsub_subscription(user, attrs \\ %{}) do
    user
    |> Ecto.build_assoc(:eventsub_subscriptions)
    |> EventsubSubscription.changeset(attrs)
    |> Repo.insert()
  end

  def delete_eventsub_subscription(%EventsubSubscription{} = eventsub_subscription) do
    Repo.delete(eventsub_subscription)
  end

  def fetch_user_eventsub_subscriptions(%User{} = user, type) do
    EventsubSubscriptionQueries.with_user_id(user.id)
    |> EventsubSubscriptionQueries.with_type(type)
    |> Repo.one()
  end

  @spec eventsub_subscription_id(String.t()) :: EventsubSubscription.t() | nil
  def eventsub_subscription_id(subscription_id) do
    EventsubSubscriptionQueries.with_subscription_id(subscription_id)
    |> Repo.one()
  end

  @spec eventsub_subscription_id_exists?(String.t()) :: boolean
  def eventsub_subscription_id_exists?(subscription_id) do
    EventsubSubscriptionQueries.with_subscription_id(subscription_id)
    |> Repo.exists?()
  end
end
