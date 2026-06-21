defmodule StreamClosedCaptionerPhoenixWeb.Schema.SubscriptionsTest do
  # async: false required — tests mutate global UserTracker state (Phoenix.Tracker GenServer)
  use StreamClosedCaptionerPhoenixWeb.ChannelCase

  alias StreamClosedCaptionerPhoenixWeb.UserTracker

  setup_all do
    # Warm up the Absinthe pipeline so the first test does not time out waiting
    # for lazy code loading. Absinthe.Test.prime/1 is blocked by
    # AuthorizedIntrospection in non-dev envs, so we run __typename instead.
    Absinthe.run("{ __typename }", StreamClosedCaptionerPhoenixWeb.Schema)
    :ok
  end

  @subscription """
  subscription($channelId: ID!) {
    newTwitchCaption(channelId: $channelId) {
      final
      interim
    }
  }
  """

  defp subscribe_to_captions(channel_id) do
    socket =
      StreamClosedCaptionerPhoenixWeb.UserSocket
      |> socket("viewer", %{__absinthe_schema__: StreamClosedCaptionerPhoenixWeb.Schema})

    {:ok, _, socket} = subscribe_and_join(socket, Absinthe.Phoenix.Channel, "__absinthe__:control")
    ref = push(socket, "doc", %{"query" => @subscription, "variables" => %{"channelId" => channel_id}})
    {ref, socket}
  end

  test "new_twitch_caption subscription is accepted when channel has a UserTracker entry" do
    channel_id = "sub-connected-uid"
    test_pid = self()
    on_exit(fn -> UserTracker.untrack(test_pid, "active_channels", channel_id) end)

    UserTracker.track(self(), "active_channels", channel_id, %{last_publish: 0})

    {ref, _socket} = subscribe_to_captions(channel_id)
    assert_reply ref, :ok, %{subscriptionId: _}
  end

  test "new_twitch_caption subscription is accepted when connected but last_publish is stale (>300s)" do
    channel_id = "sub-stale-uid"
    test_pid = self()
    on_exit(fn -> UserTracker.untrack(test_pid, "active_channels", channel_id) end)

    stale_time = System.system_time(:second) - 400
    UserTracker.track(self(), "active_channels", channel_id, %{last_publish: stale_time})

    {ref, _socket} = subscribe_to_captions(channel_id)
    assert_reply ref, :ok, %{subscriptionId: _}
  end

  test "new_twitch_caption subscription is rejected when channel has no UserTracker entry" do
    channel_id = "sub-never-tracked-uid"

    {ref, _socket} = subscribe_to_captions(channel_id)
    assert_reply ref, :error, %{errors: _}
  end
end
