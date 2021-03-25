defmodule Zoom do
  import Helpers

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
  def send_captions_to(url, text, %Zoom.Params{} = params) do
    headers = [
      {
        {:Accept, "*/*"},
        {"Content-Type", "text/plain"}
      }
    ]

    url
    |> encode_url_and_params(params)
    |> HTTPoison.post(text, headers)
  end
end
