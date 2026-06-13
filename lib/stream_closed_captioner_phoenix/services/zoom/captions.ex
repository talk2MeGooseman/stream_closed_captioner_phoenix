defmodule Zoom.Captions do
  @behaviour Zoom.CaptionsProvider

  @impl true
  def send_captions_to(url, text, %Zoom.Params{seq: seq, lang: lang}) do
    headers = [
      {"Accept", "*/*"},
      {"Content-Type", "text/plain"}
    ]

    separator = if String.contains?(url, "?"), do: "&", else: "?"
    full_url = url <> separator <> URI.encode_query(%{seq: seq, lang: lang})

    case Req.post(full_url, body: text, headers: headers, decode_body: false, retry: false) do
      {:ok, %{status: status, body: response_body}} ->
        {:ok, %{status: status, body: response_body}}

      {:error, exception} ->
        {:error, exception}
    end
  end
end
