defmodule StreamClosedCaptionerPhoenix.Costream.Guest do
  @moduledoc """
  A co-streamer guest invited by a host via a per-guest shareable link.

  The link token only carries the guest id — authorization state (revocation,
  mute, display name) lives on this record so the host's actions take effect
  immediately, without rotating tokens.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "costream_guests" do
    field(:name, :string)
    field(:muted, :boolean, default: false)
    field(:revoked_at, :utc_datetime)
    belongs_to(:user, StreamClosedCaptionerPhoenix.Accounts.User)

    timestamps()
  end

  @doc false
  def changeset(guest, attrs) do
    guest
    |> cast(attrs, [:name])
    |> update_change(:name, &if(is_binary(&1), do: String.trim(&1), else: &1))
    |> validate_required([:name])
    |> validate_length(:name, min: 1, max: 50)
    |> foreign_key_constraint(:user_id)
  end
end
