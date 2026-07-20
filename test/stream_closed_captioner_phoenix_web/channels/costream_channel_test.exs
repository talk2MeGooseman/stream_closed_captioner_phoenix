defmodule StreamClosedCaptionerPhoenixWeb.CostreamChannelTest do
  # async: false — channel processes hit the DB, FunWithFlags cache is shared,
  # and UserTracker state is global.
  use StreamClosedCaptionerPhoenixWeb.ChannelCase, async: false

  import StreamClosedCaptionerPhoenix.Factory

  alias StreamClosedCaptionerPhoenix.Costream
  alias StreamClosedCaptionerPhoenixWeb.{CostreamChannel, UserSocket, UserTracker}

  setup do
    FunWithFlags.enable(Costream.feature_flag())
    # The DB toggle row rolls back with the sandbox; only the shared in-memory
    # cache leaks across tests, and flushing it needs no DB connection (the
    # sandbox owner is already gone when on_exit runs for channel tests).
    on_exit(fn -> FunWithFlags.Store.Cache.flush() end)

    stream_settings = insert(:stream_settings, user: build(:bare_user))
    host = stream_settings.user
    guest = insert(:costream_guest, user: host, name: "Alice")

    %{host: host, guest: guest, stream_settings: stream_settings}
  end

  defp join_as_guest(guest) do
    {:ok, guest} = Costream.get_active_guest(guest.id)

    UserSocket
    |> socket("costream_guest", %{costream_guest: guest})
    |> subscribe_and_join(CostreamChannel, "costream:#{guest.user_id}")
  end

  defp mark_host_active(host) do
    UserTracker.track(self(), "active_channels", host.uid, %{
      last_publish: System.system_time(:second)
    })
  end

  describe "join" do
    test "a guest can join their host's topic", %{guest: guest} do
      assert {:ok, %{name: "Alice", muted: false}, _socket} = join_as_guest(guest)
    end

    test "a guest cannot join another host's topic", %{guest: guest} do
      other_host = insert(:user)
      {:ok, loaded} = Costream.get_active_guest(guest.id)

      assert {:error, %{reason: "unauthorized"}} =
               UserSocket
               |> socket("costream_guest", %{costream_guest: loaded})
               |> subscribe_and_join(CostreamChannel, "costream:#{other_host.id}")
    end

    test "a revoked guest cannot rejoin even with a stale socket assign", %{guest: guest} do
      {:ok, loaded} = Costream.get_active_guest(guest.id)
      {:ok, _} = Costream.revoke_guest(guest)

      assert {:error, %{reason: "unauthorized"}} =
               UserSocket
               |> socket("costream_guest", %{costream_guest: loaded})
               |> subscribe_and_join(CostreamChannel, "costream:#{guest.user_id}")
    end

    test "the host can join their own topic read-only", %{host: host} do
      assert {:ok, _, socket} =
               UserSocket
               |> socket("user_id", %{current_user: host})
               |> subscribe_and_join(CostreamChannel, "costream:#{host.id}")

      ref = push(socket, "publish", %{"interim" => "x", "final" => ""})
      assert_reply ref, :error, %{reason: "unauthorized"}
    end

    test "another user cannot join as monitor", %{host: host} do
      intruder = insert(:user)

      assert {:error, %{reason: "unauthorized"}} =
               UserSocket
               |> socket("user_id", %{current_user: intruder})
               |> subscribe_and_join(CostreamChannel, "costream:#{host.id}")
    end
  end

  describe "publish" do
    test "is gated on the host actively captioning", %{guest: guest} do
      {:ok, _, socket} = join_as_guest(guest)

      ref = push(socket, "publish", %{"interim" => "hello", "final" => ""})
      assert_reply ref, :error, %{reason: "host_offline"}
    end

    test "fans out censored captions when the host is live", %{
      host: host,
      guest: guest,
      stream_settings: stream_settings
    } do
      {:ok, _} =
        StreamClosedCaptionerPhoenix.Settings.update_stream_settings(stream_settings, %{
          blocklist: ["poopy"]
        })

      mark_host_active(host)
      Phoenix.PubSub.subscribe(StreamClosedCaptionerPhoenix.PubSub, "caption_source:#{host.id}")

      Phoenix.PubSub.subscribe(
        StreamClosedCaptionerPhoenix.PubSub,
        Costream.monitor_topic(host.id)
      )

      {:ok, _, socket} = join_as_guest(guest)

      ref = push(socket, "publish", %{"interim" => "", "final" => "hi poopy world"})

      assert_reply ref, :ok, %{name: "Alice", final: final}
      assert final == "hi ***** world"

      assert_receive {:costream_caption_payload, %{name: "Alice", final: ^final}}
      assert_receive {:costream_caption, %{name: "Alice", final: ^final}}
    end

    test "muted guests cannot publish", %{host: host, guest: guest} do
      {:ok, _} = Costream.set_guest_muted(guest, true)
      mark_host_active(host)

      {:ok, _, socket} = join_as_guest(guest)

      ref = push(socket, "publish", %{"interim" => "hello", "final" => ""})
      assert_reply ref, :error, %{reason: "muted"}
    end

    test "the kill switch silences guests", %{
      host: host,
      guest: guest,
      stream_settings: stream_settings
    } do
      {:ok, _} =
        StreamClosedCaptionerPhoenix.Settings.update_stream_settings(stream_settings, %{
          costream_enabled: false
        })

      mark_host_active(host)
      {:ok, _, socket} = join_as_guest(guest)

      ref = push(socket, "publish", %{"interim" => "hello", "final" => ""})
      assert_reply ref, :error, %{reason: "disabled"}
    end

    test "rapid publishes get rate limited", %{host: host, guest: guest} do
      mark_host_active(host)
      {:ok, _, socket} = join_as_guest(guest)

      replies =
        for i <- 1..40 do
          ref = push(socket, "publish", %{"interim" => "msg #{i}", "final" => ""})

          receive do
            %Phoenix.Socket.Reply{ref: ^ref, status: status, payload: payload} ->
              {status, payload}
          after
            1000 -> flunk("no reply for publish #{i}")
          end
        end

      assert Enum.any?(replies, fn
               {:error, %{reason: "rate_limited"}} -> true
               _ -> false
             end)
    end
  end

  describe "control events" do
    test "guest_muted broadcast mutes the running channel", %{host: host, guest: guest} do
      mark_host_active(host)
      {:ok, _, socket} = join_as_guest(guest)

      StreamClosedCaptionerPhoenixWeb.Endpoint.broadcast(
        Costream.channel_topic(host.id),
        "guest_muted",
        %{guest_id: guest.id, muted: true}
      )

      assert_push "muted", %{muted: true}

      ref = push(socket, "publish", %{"interim" => "hello", "final" => ""})
      assert_reply ref, :error, %{reason: "muted"}
    end

    test "guest_kicked broadcast pushes kicked and stops the channel", %{
      host: host,
      guest: guest
    } do
      {:ok, _, socket} = join_as_guest(guest)
      Process.unlink(socket.channel_pid)
      monitor = Process.monitor(socket.channel_pid)

      StreamClosedCaptionerPhoenixWeb.Endpoint.broadcast(
        Costream.channel_topic(host.id),
        "guest_kicked",
        %{guest_id: guest.id}
      )

      assert_push "kicked", %{}
      assert_receive {:DOWN, ^monitor, :process, _pid, _reason}
    end

    test "control events for another guest are ignored", %{host: host, guest: guest} do
      other_guest = insert(:costream_guest, user: host, name: "Bob")
      {:ok, _, _socket} = join_as_guest(guest)

      StreamClosedCaptionerPhoenixWeb.Endpoint.broadcast(
        Costream.channel_topic(host.id),
        "guest_kicked",
        %{guest_id: other_guest.id}
      )

      refute_push "kicked", %{}
    end
  end

  describe "monitor notifications" do
    test "join and leave broadcast to the monitor topic", %{host: host, guest: guest} do
      Phoenix.PubSub.subscribe(
        StreamClosedCaptionerPhoenix.PubSub,
        Costream.monitor_topic(host.id)
      )

      {:ok, _, socket} = join_as_guest(guest)
      guest_id = guest.id
      assert_receive {:costream_guest_joined, %{guest_id: ^guest_id, name: "Alice"}}

      Process.unlink(socket.channel_pid)
      leave(socket)
      assert_receive {:costream_guest_left, %{guest_id: ^guest_id}}
    end

    test "guests receive host_status on join", %{guest: guest} do
      {:ok, _, _socket} = join_as_guest(guest)
      assert_push "host_status", %{active: false}
    end
  end
end
