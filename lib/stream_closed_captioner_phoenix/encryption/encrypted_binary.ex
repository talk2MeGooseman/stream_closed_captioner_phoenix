defmodule StreamClosedCaptionerPhoenix.Encryption.EncryptedBinary do
  @moduledoc """
  Custom Ecto type for encrypted binary fields.
  
  This type automatically encrypts data before storing in the database
  and decrypts when loading from the database.
  
  ## Usage
  
      schema "users" do
        field :azure_service_key, StreamClosedCaptionerPhoenix.Encryption.EncryptedBinary
      end
  """
  
  use Ecto.Type
  
  alias StreamClosedCaptionerPhoenix.Encryption.AES

  @impl true
  def type, do: :binary

  @impl true
  def cast(nil), do: {:ok, nil}
  def cast(""), do: {:ok, nil}
  def cast(value) when is_binary(value), do: {:ok, value}
  def cast(_), do: :error

  @impl true
  def load(nil), do: {:ok, nil}
  def load(encrypted) when is_binary(encrypted) do
    case AES.decrypt(encrypted) do
      nil -> :error
      decrypted -> {:ok, decrypted}
    end
  end
  def load(_), do: :error

  @impl true
  def dump(nil), do: {:ok, nil}
  def dump(""), do: {:ok, nil}
  def dump(value) when is_binary(value) do
    case AES.encrypt(value) do
      nil -> :error
      encrypted -> {:ok, encrypted}
    end
  end
  def dump(_), do: :error

  @impl true
  def equal?(nil, nil), do: true
  def equal?(nil, _), do: false
  def equal?(_, nil), do: false
  def equal?(value1, value2), do: value1 == value2
end
