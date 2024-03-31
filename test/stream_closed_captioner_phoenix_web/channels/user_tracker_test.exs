defmodule StreamClosedCaptionerPhoenixWeb.UserTrackerTest do
  use StreamClosedCaptionerPhoenixWeb.ChannelCase, async: true

  alias StreamClosedCaptionerPhoenixWeb.UserTracker

  # setup do
  #   on_exit(fn ->
  #     for pid <- UserTracker.fetchers_pids() do
  #       ref = Process.monitor(pid)
  #       assert_receive {:DOWN, ^ref, _, _, _}, 1000
  #     end
  #   end)
  # end

  setup do
    UserTracker.untrack(self(), "active_channels", "123")
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
end
