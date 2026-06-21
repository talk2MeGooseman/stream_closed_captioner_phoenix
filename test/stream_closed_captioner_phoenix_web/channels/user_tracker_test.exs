defmodule StreamClosedCaptionerPhoenixWeb.UserTrackerTest do
  use StreamClosedCaptionerPhoenixWeb.ChannelCase

  alias StreamClosedCaptionerPhoenixWeb.UserTracker

  setup do
    test_pid = self()
    on_exit(fn -> UserTracker.untrack(test_pid, "active_channels", "123") end)
    :ok
  end

  test "recently_active_channels/0 return empty list when no channels are active" do
    assert UserTracker.recently_active_channels() == []
  end

  test "recently_active_channels/0 return list of active channels" do
    UserTracker.track(self(), "active_channels", "123", %{
      last_publish: System.system_time(:second)
    })

    assert UserTracker.recently_active_channels() == ["123"]
  end

  test "channel_active?/1 return false when channel is not present" do
    assert UserTracker.channel_active?("123") == false
  end

  test "channel_active?/1 return false when channel has no activity" do
    UserTracker.track(self(), "active_channels", "123", %{})
    assert UserTracker.channel_active?("123") == false
  end

  test "channel_active?/1 return true when channel was recently active" do
    UserTracker.track(self(), "active_channels", "123", %{
      last_publish: System.system_time(:second)
    })

    assert UserTracker.channel_active?("123") == true
  end

  test "channel_connected?/1 returns true when a UserTracker entry exists" do
    test_pid = self()
    on_exit(fn -> UserTracker.untrack(test_pid, "active_channels", "uid-connected") end)
    UserTracker.track(self(), "active_channels", "uid-connected", %{last_publish: 0})
    assert UserTracker.channel_connected?("uid-connected") == true
  end

  test "channel_connected?/1 returns false when no UserTracker entry exists" do
    assert UserTracker.channel_connected?("uid-never-tracked") == false
  end

  test "channel_connected?/1 returns true even when last_publish is stale (>300s ago)" do
    test_pid = self()
    stale_time = System.system_time(:second) - 400
    on_exit(fn -> UserTracker.untrack(test_pid, "active_channels", "uid-stale") end)
    UserTracker.track(self(), "active_channels", "uid-stale", %{last_publish: stale_time})
    assert UserTracker.channel_connected?("uid-stale") == true
    assert UserTracker.channel_active?("uid-stale") == false
  end
end
