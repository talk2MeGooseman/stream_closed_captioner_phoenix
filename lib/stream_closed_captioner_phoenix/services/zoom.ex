defmodule Zoom do
  def api_client,
    do: Application.get_env(:stream_closed_captioner_phoenix, :zoom_captions_client)

  @spec send_captions_to(String.t(), String.t(), Zoom.Params.t()) ::
          {:ok,
           HTTPoison.Response.t() | HTTPoison.AsyncResponse.t() | HTTPoison.MaybeRedirect.t()}
          | {:error, HTTPoison.Error.t()}
  def send_captions_to(url, text, %Zoom.Params{} = params) do
    api_client().send_captions_to(url, text, params)
  end
end
