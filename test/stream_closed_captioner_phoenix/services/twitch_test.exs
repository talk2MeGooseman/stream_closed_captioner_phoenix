defmodule StreamClosedCaptionerPhoenix.Services.TwitchTest do
  use ExUnit.Case, async: true

  import Mox

  setup :verify_on_exit!

  alias Twitch.Extension.CaptionsPayload

  @channel_id "123456"
  @payload %CaptionsPayload{interim: "hello", final: "hello world", delay: 0.5}

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
end
