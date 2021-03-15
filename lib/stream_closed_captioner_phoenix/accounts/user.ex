defmodule StreamClosedCaptionerPhoenix.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset
  use Waffle.Ecto.Schema

  @derive {Inspect, except: [:password]}
  schema "users" do
    field :email, :string
    field :password, :string, virtual: true
    field :encrypted_password, :string
    field :reset_password_token, :string
    field :reset_password_sent_at, :naive_datetime
    field :remember_created_at, :naive_datetime
    field :sign_in_count, :integer
    field :last_sign_in_at, :naive_datetime
    field :provider, :string
    field :uid, :string
    field :username, :string
    field :profile_image_url, :string
    field :login, :string
    field :description, :string
    field :offline_image_url, :string

    has_one :bits_balance, StreamClosedCaptionerPhoenix.Bits.BitsBalance
    has_many :bits_balance_debits, StreamClosedCaptionerPhoenix.Bits.BitsBalanceDebit
    has_many :bits_transactions, StreamClosedCaptionerPhoenix.Bits.BitsTransaction
    has_one :stream_settings, StreamClosedCaptionerPhoenix.Settings.StreamSettings
    has_many :transcripts, StreamClosedCaptionerPhoenix.Transcripts.Transcript
    has_many :transcript_messages, through: [:transcripts, :messages]
    has_many :translate_languages, StreamClosedCaptionerPhoenix.Settings.TranslateLanguage

    timestamps(inserted_at: :created_at)
  end

  @doc """
  A user changeset for registration.

  It is important to validate the length of both email and password.
  Otherwise databases may truncate the email without warnings, which
  could lead to unpredictable or insecure behaviour. Long passwords may
  also be very expensive to hash for certain algorithms.

  ## Options

    * `:encrypted_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.
  """
  def registration_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [
      :email,
      :password,
      :username,
      :profile_image_url,
      :login,
      :description,
      :offline_image_url,
      :uid
    ])
    |> unique_constraint(:uid, name: "index_users_on_uid")
    |> validate_email()
    |> validate_password(opts)
  end

  def oauth_update_changeset(user, attrs) do
    user
    |> cast(attrs, [
      :username,
      :profile_image_url,
      :login,
      :description,
      :offline_image_url
    ])
    |> validate_required([:username, :login])
  end

  defp validate_email(changeset) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> unsafe_validate_unique(:email, StreamClosedCaptionerPhoenix.Repo)
    |> update_change(:email, &String.downcase/1)
    |> unique_constraint(:email, name: "index_users_on_email")
  end

  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 6, max: 80)
    # |> validate_format(:password, ~r/[a-z]/, message: "at least one lower case character")
    # |> validate_format(:password, ~r/[A-Z]/, message: "at least one upper case character")
    # |> validate_format(:password, ~r/[!?@#$%^&*_0-9]/, message: "at least one digit or punctuation character")
    |> maybe_hash_password(opts)
  end

  defp maybe_hash_password(changeset, opts) do
    encrypted_password? = Keyword.get(opts, :encrypted_password, true)
    password = get_change(changeset, :password)

    if encrypted_password? && password && changeset.valid? do
      changeset
      |> put_change(:encrypted_password, Bcrypt.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  @doc """
  A user changeset for changing the email.

  It requires the email to change otherwise an error is added.
  """
  def email_changeset(user, attrs) do
    user
    |> cast(attrs, [:email])
    |> validate_email()
    |> case do
      %{changes: %{email: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :email, "did not change")
    end
  end

  @doc """
  A user changeset for changing the password.

  ## Options

    * `:encrypted_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.
  """
  def password_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
  end

  @doc """
  Verifies the password.

  If there is no user or the user doesn't have a password, we call
  `Bcrypt.no_user_verify/0` to avoid timing attacks.
  """
  def valid_password?(
        %StreamClosedCaptionerPhoenix.Accounts.User{encrypted_password: encrypted_password},
        password
      )
      when is_binary(encrypted_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, encrypted_password)
  end

  def valid_password?(_, _) do
    Bcrypt.no_user_verify()
    false
  end

  @doc """
  Validates the current password otherwise adds an error to the changeset.
  """
  def validate_current_password(changeset, password) do
    if valid_password?(changeset.data, password) do
      changeset
    else
      add_error(changeset, :current_password, "is not valid")
    end
  end

  def avatar_changeset(user, attrs) do
    user
    |> cast(attrs, [])
    |> cast_attachments(attrs, [:avatar])
  end
end
