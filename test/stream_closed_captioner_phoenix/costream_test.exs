defmodule StreamClosedCaptionerPhoenix.CostreamTest do
  # async: false because FunWithFlags keeps flag state in a shared in-memory cache.
  use StreamClosedCaptionerPhoenix.DataCase, async: false

  import StreamClosedCaptionerPhoenix.Factory

  alias StreamClosedCaptionerPhoenix.Costream

  setup do
    # DB toggle rows roll back with the sandbox; flush only the shared cache.
    on_exit(fn -> FunWithFlags.Store.Cache.flush() end)
    %{host: insert(:user)}
  end

  describe "create_guest/2" do
    test "creates a guest with a trimmed name", %{host: host} do
      assert {:ok, guest} = Costream.create_guest(host, %{name: "  Alice  "})
      assert guest.name == "Alice"
      assert guest.user_id == host.id
      refute guest.muted
      assert guest.revoked_at == nil
    end

    test "requires a name", %{host: host} do
      assert {:error, %Ecto.Changeset{}} = Costream.create_guest(host, %{name: "   "})
    end

    test "caps active guests", %{host: host} do
      for i <- 1..Costream.max_active_guests() do
        assert {:ok, _} = Costream.create_guest(host, %{name: "Guest #{i}"})
      end

      assert {:error, :guest_limit_reached} = Costream.create_guest(host, %{name: "One more"})
    end

    test "revoked guests do not count against the cap", %{host: host} do
      for i <- 1..Costream.max_active_guests() do
        assert {:ok, _} = Costream.create_guest(host, %{name: "Guest #{i}"})
      end

      [guest | _] = Costream.list_active_guests(host)
      assert {:ok, _} = Costream.revoke_guest(guest)
      assert {:ok, _} = Costream.create_guest(host, %{name: "Replacement"})
    end
  end

  describe "list_active_guests/1" do
    test "excludes revoked guests and other hosts' guests", %{host: host} do
      mine = insert(:costream_guest, user: host)
      revoked = insert(:costream_guest, user: host, revoked_at: DateTime.utc_now(:second))
      _other = insert(:costream_guest)

      ids = host |> Costream.list_active_guests() |> Enum.map(& &1.id)
      assert ids == [mine.id]
      refute revoked.id in ids
    end
  end

  describe "get_guest_for/2" do
    test "scopes to the host", %{host: host} do
      guest = insert(:costream_guest, user: host)
      other_hosts_guest = insert(:costream_guest)

      assert {:ok, %{id: id}} = Costream.get_guest_for(host, guest.id)
      assert id == guest.id
      assert {:error, :not_found} = Costream.get_guest_for(host, other_hosts_guest.id)
    end
  end

  describe "guest tokens" do
    test "round-trips for an active guest with the flag on", %{host: host} do
      FunWithFlags.enable(Costream.feature_flag())
      guest = insert(:costream_guest, user: host)

      token = Costream.guest_token(guest)
      assert {:ok, verified} = Costream.verify_guest_token(token)
      assert verified.id == guest.id
      assert verified.user.id == host.id
    end

    test "rejects a revoked guest's token", %{host: host} do
      FunWithFlags.enable(Costream.feature_flag())
      guest = insert(:costream_guest, user: host)
      token = Costream.guest_token(guest)

      {:ok, _} = Costream.revoke_guest(guest)
      assert {:error, :invalid} = Costream.verify_guest_token(token)
    end

    test "rejects when the feature flag is off", %{host: host} do
      guest = insert(:costream_guest, user: host)
      token = Costream.guest_token(guest)

      assert {:error, :feature_disabled} = Costream.verify_guest_token(token)
    end

    test "rejects garbage tokens" do
      assert {:error, :invalid} = Costream.verify_guest_token("not-a-token")
      assert {:error, :invalid} = Costream.verify_guest_token(nil)
    end
  end

  describe "publishing_enabled?/1" do
    test "requires flag and kill switch", %{host: host} do
      refute Costream.publishing_enabled?(host)

      FunWithFlags.enable(Costream.feature_flag())
      assert Costream.publishing_enabled?(host)

      {:ok, _} =
        StreamClosedCaptionerPhoenix.Settings.update_stream_settings(
          host.stream_settings,
          %{costream_enabled: false}
        )

      refute Costream.publishing_enabled?(host)
    end
  end

  describe "set_guest_muted/2" do
    test "flips the muted flag", %{host: host} do
      guest = insert(:costream_guest, user: host)

      assert {:ok, %{muted: true}} = Costream.set_guest_muted(guest, true)
      assert {:ok, %{muted: false}} = Costream.set_guest_muted(%{guest | muted: true}, false)
    end
  end
end
