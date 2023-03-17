defmodule StreamClosedCaptionerPhoenixWeb.ActivePresenceTest do
	use StreamClosedCaptionerPhoenixWeb.ChannelCase, async: true

	alias StreamClosedCaptionerPhoenixWeb.ActivePresence

  setup do
    on_exit(fn ->
      for pid <- ActivePresence.fetchers_pids() do
        ref = Process.monitor(pid)
        assert_receive {:DOWN, ^ref, _, _, _}, 1000
      end
    end)
  end

  test "recently_active_channels/0 return empty list when no channels are active" do
    assert ActivePresence.recently_active_channels() == []
  end

  test "recently_active_channels/0 return list of active channels" do
    ActivePresence.track(self(), "active_channels", "123", %{})
    assert ActivePresence.recently_active_channels() == ["123"]
  end

  test "is_channel_active?/1 return false when channel is not active" do
    assert ActivePresence.is_channel_active?("123") == false
  end

  test "is_channel_active?/1 return true when channel is active" do
    ActivePresence.track(self(), "active_channels", "123", %{})
    assert ActivePresence.is_channel_active?("123") == true
  end
end
