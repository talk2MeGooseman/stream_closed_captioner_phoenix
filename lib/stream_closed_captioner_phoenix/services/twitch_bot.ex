defmodule TwitchBot do
  use GenServer

  ### GenServer API

  @doc """
  GenServer.init/1 callback
  """
  def init(pid), do: {:ok, pid}

  @doc """
  GenServer.handle_cast/2 callback
  """
  def handle_cast({:connect, channels}, pid) do
    case GenServer.stop(pid) do
      :ok ->
        {:ok, pid} = TwitchBot.Handler.connect(channels)
        {:noreply, pid}

      _ ->
        IO.puts("OOPS")
    end
  end

  ### Client API / Helper functions

  def start_link do
    {:ok, pid} = TwitchBot.Handler.connect([])

    GenServer.start_link(__MODULE__, pid, name: __MODULE__)
  end

  def connect(channels), do: GenServer.cast(__MODULE__, {:connect, channels})
end
