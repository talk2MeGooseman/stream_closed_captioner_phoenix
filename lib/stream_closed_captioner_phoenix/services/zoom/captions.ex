defmodule Zoom.Captions do
  @behaviour Zoom.CaptionsProvider

  @impl true
  def send_captions_to(url, text, %Zoom.Params{seq: seq, lang: lang}) do
    headers = [
      {"Accept", "*/*"},
      {"Content-Type", "text/plain"}
    ]

    (url <> "&" <> URI.encode_query(%{seq: seq, lang: lang}))
    |> HTTPoison.post(text, headers)
  end
end
