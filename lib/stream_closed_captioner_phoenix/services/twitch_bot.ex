defmodule TwitchBot do
  use GenServer
  ### Client API / Helper functions

  @doc """
  Starts the gen server
  """
  def start_link(_) do
    {:ok, pid} = TwitchBot.Handler.connect([])

    GenServer.start_link(__MODULE__, pid, name: __MODULE__)
  end

  defdelegate is_logged_on?(), to: TwitchBot.Handler

  @spec connect_all(list(String.t())) :: :ok
  @doc """
  Connects to the list of channels provided, overriding previous channels
  """
  def connect_all(channels), do: GenServer.cast(__MODULE__, {:connect_all, channels})

  @spec connect_to(String.t()) :: :ok
  @doc """
  Connects to a new channel, updating the list of channels
  """
  def connect_to(channel), do: GenServer.cast(__MODULE__, {:connect_to, channel})

  @spec disconnect(String.t()) :: :ok
  def disconnect(channel), do: GenServer.cast(__MODULE__, {:disconnect, channel})

  def say(channel, message), do: GenServer.cast(__MODULE__, {:say, channel, message})

  ### GenServer API

  @spec init(any) :: {:ok, %{channels: [], pid: any}}
  @doc """
  GenServer.init/1 callback
  """
  def init(pid), do: {:ok, %{pid: pid, channels: []}}

  @doc """
  GenServer.handle_cast/2 callback
  """
  def handle_cast({:connect_all, channels}, %{pid: pid}) do
    :ok = GenServer.stop(pid)
    channels = Enum.map(channels, &String.downcase/1)
    {:ok, pid} = TwitchBot.Handler.connect(channels)

    {:noreply, %{pid: pid, channels: channels}}
  end

  def handle_cast({:connect_to, channel}, %{pid: pid, channels: channels}) do
    channel = String.downcase(channel)
    # Check if the channel is in the list
    if !Enum.member?(channels, channel) do
      new_channels = [channel] ++ channels
      reconnect_all(%{pid: pid, channels: new_channels})
    else
      {:noreply, %{pid: pid, channels: channels}}
    end
  end

  def handle_cast({:disconnect, channel}, %{pid: pid, channels: channels}) do
    channel = String.downcase(channel)
    # Check if the channel is in the list
    if Enum.member?(channels, channel) do
      new_channels = List.delete(channels, channel)
      reconnect_all(%{pid: pid, channels: new_channels})
    else
      {:noreply, %{pid: pid, channels: channels}}
    end
  end

  def handle_cast({:say, channel, message}, %{pid: pid, channels: channels}) do
    channel = String.downcase(channel)
    TwitchBot.Handler.say(channel, message)
    {:noreply, %{pid: pid, channels: channels}}
  end

  defp reconnect_all(%{pid: pid, channels: channels}) do
    :ok = GenServer.stop(pid)
    {:ok, pid} = TwitchBot.Handler.connect(channels)
    {:noreply, %{pid: pid, channels: channels}}
  end
end
