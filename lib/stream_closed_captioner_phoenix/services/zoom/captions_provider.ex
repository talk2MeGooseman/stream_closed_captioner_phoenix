defmodule Zoom.CaptionsProvider do
  @callback send_captions_to(String.t(), String.t(), Zoom.Params.t()) ::
              {:ok,
               HTTPoison.Response.t() | HTTPoison.AsyncResponse.t() | HTTPoison.MaybeRedirect.t()}
              | {:error, HTTPoison.Error.t()}
end
