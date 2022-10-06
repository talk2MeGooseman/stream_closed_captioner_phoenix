defmodule DeepgramWebsocket do
  use WebSockex

  def start_link(state \\ %{}, opts \\ []) do
    socket_opts = [
      extra_headers: [
        {"Authorization",
         "Token " <> Application.get_env(:stream_closed_captioner_phoenix, :deepgram_token)}
      ]
    ]

    opts = Keyword.merge(opts, socket_opts)

    WebSockex.start_link(
      "wss://api.deepgram.com/v1/listen?model=general-enhanced&punctuate=true&interim_results=true",
      __MODULE__,
      state,
      opts
    )
  end

  def handle_frame({_type, msg}, state) do
    value = StreamClosedCaptionerPhoenix.DeepgramResponse.new(Jason.decode!(msg))
    text = List.first(value.channel.alternatives) |> Map.get(:transcript)

    if String.length(text) > 0 do
      payload =
        if value.is_final do
          %{
            final: text
          }
        else
          %{
            interim: text
          }
        end

      case StreamClosedCaptionerPhoenix.CaptionsPipeline.pipeline_to(:twitch, state.user, payload) do
        {:ok, sent_payload} ->
          Absinthe.Subscription.publish(StreamClosedCaptionerPhoenixWeb.Endpoint, sent_payload,
            new_twitch_caption: state.user.uid
          )

        {:error, _} ->
          dbg("Error sending payload")
      end
    end

    {:ok, state}
  end
end
