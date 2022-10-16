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
    # Need to tailor this to the service were sending to
    NewRelic.start_transaction("Captions", "twitch")
    deepgram_response = StreamClosedCaptionerPhoenix.DeepgramResponse.new(Jason.decode!(msg))
    transcript = List.first(deepgram_response.channel.alternatives) |> Map.get(:transcript)

    if String.length(transcript) > 0 do
      payload =
        if deepgram_response.is_final do
          %{
            "final" => transcript,
            "sentOn" => System.system_time(:second)
          }
        else
          %{
            "interim" => transcript,
            "sentOn" => System.system_time(:second)
          }
        end

      case StreamClosedCaptionerPhoenix.CaptionsPipeline.pipeline_to(:twitch, state.user, payload) do
        {:ok, sent_payload} ->
          # Still need to broadcast to show what is being transcribed
          StreamClosedCaptionerPhoenixWeb.Endpoint.broadcast(
            "captions:#{state.user.id}",
            "deepgram",
            sent_payload
          )

          new_relic_track(:ok, state.user)

        {:error, _} ->
          new_relic_track(:error, state.user)
      end
    end

    {:ok, state}
  end

  defp new_relic_track(:ok, user) do
    NewRelic.add_attributes(twitch_uid: user.uid)
    NewRelic.stop_transaction()
  end

  defp new_relic_track(:error, user) do
    NewRelic.add_attributes(errored: true)
    new_relic_track(:ok, user)
  end
end
