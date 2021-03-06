defmodule StreamClosedCaptionerPhoenix.Transcripts do
  @moduledoc """
  The Transcirpts context.
  """

  import Ecto.Query, warn: false
  alias StreamClosedCaptionerPhoenix.Repo

  alias StreamClosedCaptionerPhoenix.Accounts.User
  alias StreamClosedCaptionerPhoenix.Transcripts.{Message, Transcript}

  @doc """
  Returns the list of transcripts by user_id.

  ## Examples

      iex> list_user_transcripts(%{ id: 1 })
      [%Transcript{}, ...]

  """
  def list_user_transcripts(%{id: id}) do
    Transcript |> where([p], p.user_id == ^id) |> Repo.all()
  end

  @doc """
  Returns the list of transcripts.

  ## Examples

      iex> list_transcripts()
      [%Transcript{}, ...]

  """
  def list_transcripts do
    Repo.all(Transcript)
  end

  @doc """
  Gets a single transcript.

  Raises `Ecto.NoResultsError` if the Transcript does not exist.

  ## Examples

      iex> get_transcript!(123)
      %Transcript{}

      iex> get_transcript!(456)
      ** (Ecto.NoResultsError)

  """
  def get_transcript!(id), do: Repo.get!(Transcript, id)

  @doc """
  Gets a single transcript scope to the user.

  Raises `Ecto.NoResultsError` if the Transcript does not exist.

  ## Examples

      iex> get_users_transcript!(%{ user_id: 1 })
      %Transcript{}

      iex> get_users_transcript!(%{ user_id: 3 })
      ** (Ecto.NoResultsError)

  """
  def get_users_transcript!(%{id: user_id}, id),
    do: Transcript |> where(user_id: ^user_id) |> where(id: ^id) |> Repo.one!()

  @doc """
  Creates a transcript.

  ## Examples

      iex> create_transcript(user, %{field: value})
      {:ok, %Transcript{}}

      iex> create_transcript(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_transcript(%User{} = user, attrs \\ %{}) do
    user
    |> Ecto.build_assoc(:transcripts)
    |> Transcript.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a transcript.

  ## Examples

      iex> update_transcript(transcript, %{field: new_value})
      {:ok, %Transcript{}}

      iex> update_transcript(transcript, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_transcript(%Transcript{} = transcript, attrs) do
    transcript
    |> Transcript.update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a transcript.

  ## Examples

      iex> delete_transcript(transcript)
      {:ok, %Transcript{}}

      iex> delete_transcript(transcript)
      {:error, %Ecto.Changeset{}}

  """
  def delete_transcript(%Transcript{} = transcript) do
    Repo.delete(transcript)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking transcript changes.

  ## Examples

      iex> change_transcript(transcript)
      %Ecto.Changeset{data: %Transcript{}}

  """
  def change_transcript(%Transcript{} = transcript, attrs \\ %{}) do
    Transcript.changeset(transcript, attrs)
  end

  @doc """
  Returns the list of messages.

  ## Examples

      iex> list_messages()
      [%Message{}, ...]

  """
  def list_messages do
    Repo.all(Message)
  end

  @doc """
  Gets a single message.

  Raises `Ecto.NoResultsError` if the Message does not exist.

  ## Examples

      iex> get_message!(123)
      %Message{}

      iex> get_message!(456)
      ** (Ecto.NoResultsError)

  """
  def get_message!(id), do: Message |> Repo.get!(id)

  @doc """
  Gets a single message for a transcript.

  Raises `Ecto.NoResultsError` if the Message does not exist.

  ## Examples

      iex> get_users_message!(transcript, 123)
      %Message{}

      iex> get_users_message!(transcript, 456)
      ** (Ecto.NoResultsError)

  """
  def get_transcripts_message!(%Transcript{} = transcript, id) do
    Message
    |> where(transcript_id: ^transcript.id)
    |> where(id: ^id)
    |> Repo.one!()
  end

  @doc """
  Creates a message.

  ## Examples

      iex> create_message(transcript, %{field: value})
      {:ok, %Message{}}

      iex> create_message(transcript, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_message(%Transcript{} = transcript, attrs \\ %{}) do
    transcript
    |> Ecto.build_assoc(:messages)
    |> Message.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a message.

  ## Examples

      iex> update_message(message, %{field: new_value})
      {:ok, %Message{}}

      iex> update_message(message, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_message(%Message{} = message, attrs) do
    message
    |> Message.update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a message.

  ## Examples

      iex> delete_message(message)
      {:ok, %Message{}}

      iex> delete_message(message)
      {:error, %Ecto.Changeset{}}

  """
  def delete_message(%Message{} = message) do
    Repo.delete(message)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking message changes.

  ## Examples

      iex> change_message(message)
      %Ecto.Changeset{data: %Message{}}

  """
  def change_message(%Message{} = message, attrs \\ %{}) do
    Message.changeset(message, attrs)
  end
end
