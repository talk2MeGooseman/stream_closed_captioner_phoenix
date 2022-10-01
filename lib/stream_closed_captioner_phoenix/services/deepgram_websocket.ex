defmodule DeepgramWebsocket do
  use WebSockex

  def start_link(opts \\ []) do
    socket_opts = [
      extra_headers: [
        {"Authorization", "Token <TOKEN HERE>"}
      ]
    ]

    opts = Keyword.merge(opts, socket_opts)

    WebSockex.start_link(
      "wss://api.deepgram.com/v1/listen?model=general-enhanced&punctuate=true&interim_results=true",
      __MODULE__,
      %{},
      opts
    )
  end

  def handle_frame({type, msg}, state) do
    IO.puts("Received Message - #{inspect(msg)}")
    value = StreamClosedCaptionerPhoenix.DeepgramResponse.new(Jason.decode!(msg))
    IO.puts("Parsed Message: #{inspect(value)}")

    {:ok, state}
  end
end
