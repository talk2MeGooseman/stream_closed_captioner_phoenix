defmodule StreamClosedCaptionerPhoenix.Settings do
  @moduledoc """
  The Settings context.
  """

  import Ecto.Query, warn: false
  alias StreamClosedCaptionerPhoenix.Repo

  alias StreamClosedCaptionerPhoenix.Settings.StreamSettings

  @doc """
  Returns the list of stream_settings.

  ## Examples

      iex> list_stream_settings()
      [%StreamSettings{}, ...]

  """
  def list_stream_settings do
    Repo.all(StreamSettings)
  end

  @doc """
  Gets a single stream_settings.

  Raises `Ecto.NoResultsError` if the Stream settings does not exist.

  ## Examples

      iex> get_stream_settings!(123)
      %StreamSettings{}

      iex> get_stream_settings!(456)
      ** (Ecto.NoResultsError)

  """
  def get_stream_settings!(id), do: Repo.get!(StreamSettings, id)

  @doc """
  Gets a single stream_setting by user id.

  Raises `Ecto.NoResultsError` if the Stream settings does not exist.

  ## Examples

      iex> get_stream_settings_by_user_id!(123)
      %StreamSettings{}

      iex> get_stream_settings_by_user_id!(456)
      ** (Ecto.NoResultsError)

  """
  def get_stream_settings_by_user_id!(id),
    do: Repo.get_by!(StreamSettings, user_id: id)

  @doc """
  Creates a stream_settings.

  ## Examples

      iex> create_stream_settings(%{field: value})
      {:ok, %StreamSettings{}}

      iex> create_stream_settings(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_stream_settings(attrs \\ %{}) do
    %StreamSettings{}
    |> StreamSettings.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a stream_settings.

  ## Examples

      iex> update_stream_settings(stream_settings, %{field: new_value})
      {:ok, %StreamSettings{}}

      iex> update_stream_settings(stream_settings, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_stream_settings(%StreamSettings{} = stream_settings, attrs) do
    stream_settings
    |> StreamSettings.update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a stream_settings.

  ## Examples

      iex> delete_stream_settings(stream_settings)
      {:ok, %StreamSettings{}}

      iex> delete_stream_settings(stream_settings)
      {:error, %Ecto.Changeset{}}

  """
  def delete_stream_settings(%StreamSettings{} = stream_settings) do
    Repo.delete(stream_settings)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking stream_settings changes.

  ## Examples

      iex> change_stream_settings(stream_settings)
      %Ecto.Changeset{data: %StreamSettings{}}

  """
  def change_stream_settings(%StreamSettings{} = stream_settings, attrs \\ %{}) do
    StreamSettings.changeset(stream_settings, attrs)
  end
end
