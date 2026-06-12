defmodule StreamClosedCaptionerPhoenix.Services.TwitchTest do
  # async: false because get_live_streams tests exercise the shared Cache singleton.
  use ExUnit.Case, async: false

  import Mox

  setup :verify_on_exit!

  alias StreamClosedCaptionerPhoenix.Cache
  alias Twitch.Extension.CaptionsPayload
  alias Twitch.Helix.{Credentials, Stream}

  @channel_id "123456"
  @payload %CaptionsPayload{interim: "hello", final: "hello world", delay: 0.5}

  @credentials %Credentials{
    client_id: "TWITCHCLIENTID",
    client_secret: "TWITCHCLIENTSECRET",
    access_token: "test_access_token"
  }

  describe "send_pubsub_message/2" do
    test "returns error when channel_id is nil" do
      assert {:error, "Missing Channel ID"} =
               Twitch.send_pubsub_message(@payload, nil)
    end

    test "returns {:ok, payload} on 204 response" do
      expect(Twitch.MockExtension, :send_pubsub_message_for, fn _credentials,
                                                                _channel_id,
                                                                _payload ->
        {:ok, %HTTPoison.Response{status_code: 204, body: ""}}
      end)

      assert {:ok, @payload} = Twitch.send_pubsub_message(@payload, @channel_id)
    end

    test "returns {:error, message} on 400 response" do
      expect(Twitch.MockExtension, :send_pubsub_message_for, fn _credentials,
                                                                _channel_id,
                                                                _payload ->
        {:ok, %HTTPoison.Response{status_code: 400, body: "Bad Request"}}
      end)

      assert {:error, "Request was rejected"} =
               Twitch.send_pubsub_message(@payload, @channel_id)
    end

    test "returns {:error, message} on 500 response" do
      expect(Twitch.MockExtension, :send_pubsub_message_for, fn _credentials,
                                                                _channel_id,
                                                                _payload ->
        {:ok, %HTTPoison.Response{status_code: 500, body: "Internal Server Error"}}
      end)

      assert {:error, "500, Twitch throwing errors for some reason."} =
               Twitch.send_pubsub_message(@payload, @channel_id)
    end

    test "returns {:error, message} on 502 response" do
      expect(Twitch.MockExtension, :send_pubsub_message_for, fn _credentials,
                                                                _channel_id,
                                                                _payload ->
        {:ok, %HTTPoison.Response{status_code: 502, body: "Bad Gateway"}}
      end)

      assert {:error, "502, cant reach Twitch atm."} =
               Twitch.send_pubsub_message(@payload, @channel_id)
    end

    test "returns {:error, reason} on HTTPoison.Error" do
      expect(Twitch.MockExtension, :send_pubsub_message_for, fn _credentials,
                                                                _channel_id,
                                                                _payload ->
        {:error, %HTTPoison.Error{reason: :timeout}}
      end)

      assert {:error, :timeout} = Twitch.send_pubsub_message(@payload, @channel_id)
    end
  end

  describe "get_live_streams/1" do
    # Clear cache before each test so results from one test cannot bleed into the next.
    setup do
      Cache.delete_all()
      :ok
    end

    test "returns [] immediately for empty input without touching OAuth or Helix" do
      # No expectations set — Mox will fail verify_on_exit! if either mock is called.
      assert [] == Twitch.get_live_streams([])
    end

    test "returns [] and logs a warning when OAuth fails" do
      expect(Twitch.MockOauth, :get_client_access_token, fn ->
        {:error, {:http, :econnrefused}}
      end)

      assert [] == Twitch.get_live_streams(["123"])
    end

    test "fetches the client token exactly once for a single chunk and passes it to Helix" do
      user_ids = ["100", "200"]

      # Mox enforces the count: exactly 1 OAuth call, exactly 1 Helix call.
      expect(Twitch.MockOauth, :get_client_access_token, 1, fn ->
        {:ok, @credentials}
      end)

      expect(Twitch.MockHelix, :get_streams, 1, fn creds, ^user_ids, nil ->
        assert creds == @credentials

        [
          %Stream{user_id: "200", viewer_count: 200},
          %Stream{user_id: "100", viewer_count: 100}
        ]
      end)

      result = Twitch.get_live_streams(user_ids)

      assert [%Stream{user_id: "200"}, %Stream{user_id: "100"}] = result
    end

    test "fetches the client token exactly once even when user_ids span multiple Helix chunks" do
      # 82 IDs → chunk_every(80) produces 2 chunks; token must be fetched only once.
      user_ids = Enum.map(1..82, &Integer.to_string/1)
      [chunk_1, chunk_2] = Enum.chunk_every(user_ids, 80)

      expect(Twitch.MockOauth, :get_client_access_token, 1, fn ->
        {:ok, @credentials}
      end)

      expect(Twitch.MockHelix, :get_streams, fn _creds, ^chunk_1, nil ->
        [%Stream{user_id: "1", viewer_count: 50}]
      end)

      expect(Twitch.MockHelix, :get_streams, fn _creds, ^chunk_2, nil ->
        [%Stream{user_id: "81", viewer_count: 300}]
      end)

      result = Twitch.get_live_streams(user_ids)

      assert length(result) == 2
      # Final sort is by viewer_count descending.
      assert hd(result).user_id == "81"
      assert hd(result).viewer_count == 300
    end

    test "returns streams sorted by viewer_count descending" do
      expect(Twitch.MockOauth, :get_client_access_token, fn -> {:ok, @credentials} end)

      expect(Twitch.MockHelix, :get_streams, fn _creds, _uids, nil ->
        [
          %Stream{user_id: "a", viewer_count: 10},
          %Stream{user_id: "b", viewer_count: 500},
          %Stream{user_id: "c", viewer_count: 100}
        ]
      end)

      [first | rest] = Twitch.get_live_streams(["a", "b", "c"])

      assert first.viewer_count == 500
      assert List.last(rest).viewer_count == 10
    end

    test "deduplicates streams by user_id, keeping first occurrence after user_id desc sort" do
      expect(Twitch.MockOauth, :get_client_access_token, fn -> {:ok, @credentials} end)

      expect(Twitch.MockHelix, :get_streams, fn _creds, _uids, nil ->
        [
          %Stream{user_id: "999", viewer_count: 100},
          %Stream{user_id: "999", viewer_count: 50}
        ]
      end)

      result = Twitch.get_live_streams(["999"])

      assert length(result) == 1
      assert hd(result).user_id == "999"
    end

    test "caches the result: Helix and OAuth are called only once for repeated identical inputs" do
      user_ids = ["aaa", "bbb"]

      # Exactly 1 OAuth and 1 Helix call across 2 invocations — the second hits cache.
      expect(Twitch.MockOauth, :get_client_access_token, 1, fn -> {:ok, @credentials} end)

      expect(Twitch.MockHelix, :get_streams, 1, fn _creds, ^user_ids, nil ->
        [
          %Stream{user_id: "aaa", viewer_count: 10},
          %Stream{user_id: "bbb", viewer_count: 20}
        ]
      end)

      first_result = Twitch.get_live_streams(user_ids)
      second_result = Twitch.get_live_streams(user_ids)

      assert first_result == second_result
    end

    test "different user_id sets use independent cache slots" do
      # Two distinct inputs → two OAuth calls, two Helix calls.
      expect(Twitch.MockOauth, :get_client_access_token, 2, fn -> {:ok, @credentials} end)

      expect(Twitch.MockHelix, :get_streams, fn _creds, ["set_a"], nil ->
        [%Stream{user_id: "set_a", viewer_count: 1}]
      end)

      expect(Twitch.MockHelix, :get_streams, fn _creds, ["set_b"], nil ->
        [%Stream{user_id: "set_b", viewer_count: 2}]
      end)

      result_a = Twitch.get_live_streams(["set_a"])
      result_b = Twitch.get_live_streams(["set_b"])

      assert [%Stream{user_id: "set_a"}] = result_a
      assert [%Stream{user_id: "set_b"}] = result_b
    end

    test "cache key is order-independent: reversed input hits the same cache slot" do
      # Helix and OAuth called exactly once even though inputs are in different order.
      expect(Twitch.MockOauth, :get_client_access_token, 1, fn -> {:ok, @credentials} end)

      expect(Twitch.MockHelix, :get_streams, 1, fn _creds, _uids, nil ->
        [%Stream{user_id: "x", viewer_count: 10}]
      end)

      first = Twitch.get_live_streams(["x", "y"])
      second = Twitch.get_live_streams(["y", "x"])

      assert first == second
    end
  end
end
