defmodule Zoom do
  def api_client,
    do: Application.get_env(:stream_closed_captioner_phoenix, :zoom_captions_client)

  @spec send_captions_to(String.t(), String.t(), Zoom.Params.t()) ::
          {:ok, map()} | {:error, term()}
  def send_captions_to(url, text, %Zoom.Params{} = params) do
    api_client().send_captions_to(url, text, params)
  end
end
