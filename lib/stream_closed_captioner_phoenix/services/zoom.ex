defmodule Zoom do
  @spec send_captions_to(String.t() | URI.t(), String.t(), Zoom.Params.t()) ::
          {:error, HTTPoison.Error.t()}
          | {:ok,
             %{
               :__struct__ =>
                 HTTPoison.AsyncResponse | HTTPoison.MaybeRedirect | HTTPoison.Response,
               optional(:body) => any,
               optional(:headers) => list,
               optional(:id) => reference,
               optional(:redirect_url) => any,
               optional(:request) => HTTPoison.Request.t(),
               optional(:request_url) => any,
               optional(:status_code) => integer
             }}
  def send_captions_to(url, text, %Zoom.Params{seq: seq, lang: lang}) do
    metadata = %{
      http_status: nil,
      result: nil,
      error_reason: nil,
      host: host_of(url)
    }

    body_bytes = byte_size(text)

    headers = [
      {"Accept", "*/*"},
      {"Content-Type", "text/plain"}
    ]

    full_url = url <> "&" <> URI.encode_query(%{seq: seq, lang: lang})

    :telemetry.span([:scc, :outbound, :zoom_delivery],
      Map.put(metadata, :body_bytes, body_bytes),
      fn ->
        case HTTPoison.post(full_url, text, headers) do
          {:ok, %HTTPoison.Response{status_code: status}} = ok ->
            {ok, %{metadata | http_status: status, result: result_for(status)}}

          {:error, %HTTPoison.Error{reason: reason}} = err ->
            {err, %{metadata | result: :error, error_reason: inspect(reason)}}
        end
      end
    )
  end

  defp host_of(url) do
    case URI.parse(url) do
      %URI{host: host} -> host
      _ -> nil
    end
  end

  defp result_for(status) when status in 200..299, do: :ok
  defp result_for(_), do: :error
end
