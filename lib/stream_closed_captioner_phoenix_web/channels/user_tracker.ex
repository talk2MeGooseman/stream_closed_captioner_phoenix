defmodule StreamClosedCaptionerPhoenixWeb.UserTracker do
  @behaviour Phoenix.Tracker

  @active_time_out 300

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :supervisor
    }
  end

  def start_link(opts) do
    opts = Keyword.merge([name: __MODULE__], opts)
    Phoenix.Tracker.start_link(__MODULE__, opts, opts)
  end

  def init(opts) do
    server = Keyword.fetch!(opts, :pubsub_server)
    {:ok, %{pubsub_server: server, node_name: Phoenix.PubSub.node_name(server)}}
  end

  def handle_diff(diff, state) do
    for {topic, {joins, leaves}} <- diff do
      for {key, meta} <- joins do
        # IO.puts("#{topic} presence join: key \"#{key}\" with meta #{inspect(meta)}")
      end

      for {key, meta} <- leaves do
        # IO.puts("#{topic} presence leave: key \"#{key}\" with meta #{inspect(meta)}")
      end
    end

    {:ok, state}
  end

  def track(pid, topic, uid, metadata) do
    Phoenix.Tracker.track(__MODULE__, pid, topic, uid, metadata)
  end

  def list(topic \\ "active_channels") do
    Phoenix.Tracker.list(__MODULE__, topic)
  end

  def get_by_key(topic \\ "active_channels", key) do
    Phoenix.Tracker.get_by_key(__MODULE__, topic, key)
  end

  def update(pid, topic, uid, metadata) do
    Phoenix.Tracker.update(__MODULE__, pid, topic, uid, metadata)
  end

  def untrack(pid, topic, uid) do
    Phoenix.Tracker.untrack(__MODULE__, pid, topic, uid)
  end

  def recently_active_channels do
    StreamClosedCaptionerPhoenixWeb.UserTracker.list("active_channels")
    |> Enum.reduce([], &reduced_user_list/2)
  end

  def channel_active?(channel_id) do
    StreamClosedCaptionerPhoenixWeb.UserTracker.get_by_key("active_channels", channel_id)
    |> List.first()
    |> channel_recently_published?()
  end

  defp reduced_user_list({uid, metadata}, acc) when is_binary(uid) do
    elapsed_time = current_timestamp() - get_last_publish(metadata)

    if currently_active(elapsed_time) do
      [uid | acc]
    else
      acc
    end
  end

  defp reduced_user_list(_, acc), do: acc

  defp channel_recently_published?({_uid, metadata}) do
    elapsed_time = current_timestamp() - get_last_publish(metadata)
    currently_active(elapsed_time)
  end

  defp channel_recently_published?([]), do: false

  defp channel_recently_published?(nil), do: false

  defp current_timestamp, do: System.system_time(:second)

  defp get_last_publish(metadata),
    do: Map.get(metadata, :last_publish, 0)

  defp currently_active(elapsed_time), do: elapsed_time <= @active_time_out
end
