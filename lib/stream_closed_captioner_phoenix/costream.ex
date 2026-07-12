defmodule StreamClosedCaptionerPhoenix.Costream do
  @moduledoc """
  Co-streamer guest captions.

  A host creates per-guest shareable links; whoever opens a link gets a guest
  dashboard that transcribes their speech in the browser and publishes it to
  `CostreamChannel`. Guest captions are censored with the host's settings and
  fanned out to the Twitch extension (`new_costream_caption` subscription) and
  the OBS overlay — never translated or pirate-moded, keeping the guest path
  cheap enough to run for several concurrent speakers.

  The whole feature is gated by the `#{inspect(:costream_captions)}` feature
  flag (per host) plus the `costream_enabled` kill switch on stream settings.
  """
  import Ecto.Query, warn: false

  alias StreamClosedCaptionerPhoenix.Accounts.User
  alias StreamClosedCaptionerPhoenix.Costream.Guest
  alias StreamClosedCaptionerPhoenix.{Repo, Settings}

  @feature_flag :costream_captions
  @max_active_guests 4
  @token_salt "costream guest"

  def feature_flag, do: @feature_flag
  def max_active_guests, do: @max_active_guests

  @doc "Whether the costream feature is rolled out to this host at all."
  def feature_enabled?(%User{} = user), do: FunWithFlags.enabled?(@feature_flag, for: user)

  @doc """
  Whether guests may currently publish for this host: feature flag AND the
  host's `costream_enabled` kill switch. Checked on every guest publish so
  flipping the switch silences guests instantly.
  """
  def publishing_enabled?(%User{} = host) do
    feature_enabled?(host) and
      case Settings.get_stream_settings_by_user_id(host.id) do
        {:ok, stream_settings} -> stream_settings.costream_enabled
        {:error, _} -> false
      end
  end

  @doc "Active (unrevoked) guests for a host, oldest first."
  def list_active_guests(%User{id: user_id}) do
    Guest
    |> where([g], g.user_id == ^user_id and is_nil(g.revoked_at))
    |> order_by([g], asc: g.id)
    |> Repo.all()
  end

  @doc "Fetches a guest scoped to its host, so hosts can only manage their own."
  def get_guest_for(%User{id: user_id}, id) do
    case Repo.get_by(Guest, id: id, user_id: user_id) do
      nil -> {:error, :not_found}
      guest -> {:ok, guest}
    end
  end

  @doc "Fetches an unrevoked guest with the host user preloaded."
  def get_active_guest(id) do
    case Repo.get(Guest, id) do
      %Guest{revoked_at: nil} = guest -> {:ok, Repo.preload(guest, :user)}
      _ -> {:error, :not_found}
    end
  end

  @doc """
  Creates a guest link for a host, capped at #{@max_active_guests} active
  guests so extension layout and fan-out stay bounded.
  """
  def create_guest(%User{id: user_id} = host, attrs) do
    active_count =
      Guest
      |> where([g], g.user_id == ^user_id and is_nil(g.revoked_at))
      |> Repo.aggregate(:count)

    if active_count >= @max_active_guests do
      {:error, :guest_limit_reached}
    else
      %Guest{user_id: host.id}
      |> Guest.changeset(attrs)
      |> Repo.insert()
    end
  end

  @doc "Permanently disables a guest link. Existing tokens stop verifying."
  def revoke_guest(%Guest{} = guest) do
    guest
    |> Ecto.Changeset.change(revoked_at: DateTime.truncate(DateTime.utc_now(), :second))
    |> Repo.update()
  end

  def set_guest_muted(%Guest{} = guest, muted) when is_boolean(muted) do
    guest
    |> Ecto.Changeset.change(muted: muted)
    |> Repo.update()
  end

  @doc """
  Signs a standing link token for a guest. The token never expires on its
  own — revocation is the `revoked_at` flag, checked on every verify.
  """
  def guest_token(%Guest{id: id}) do
    Phoenix.Token.sign(StreamClosedCaptionerPhoenixWeb.Endpoint, @token_salt, id)
  end

  @doc """
  Verifies a guest link token: signature, guest not revoked, and the host's
  feature flag still on. Returns the guest with the host user preloaded.
  """
  def verify_guest_token(token) when is_binary(token) do
    with {:ok, guest_id} <-
           Phoenix.Token.verify(StreamClosedCaptionerPhoenixWeb.Endpoint, @token_salt, token,
             max_age: :infinity
           ),
         {:ok, %Guest{} = guest} <- get_active_guest(guest_id) do
      if feature_enabled?(guest.user) do
        {:ok, guest}
      else
        {:error, :feature_disabled}
      end
    else
      _ -> {:error, :invalid}
    end
  end

  def verify_guest_token(_token), do: {:error, :invalid}

  @doc "PubSub topic the host dashboard subscribes to for live guest activity."
  def monitor_topic(host_user_id), do: "costream_monitor:#{host_user_id}"

  @doc "Phoenix channel topic guests and the host monitor join."
  def channel_topic(host_user_id), do: "costream:#{host_user_id}"

  @doc "UserTracker presence topic listing currently connected guests."
  def presence_topic(host_user_id), do: "costream_guests:#{host_user_id}"
end
