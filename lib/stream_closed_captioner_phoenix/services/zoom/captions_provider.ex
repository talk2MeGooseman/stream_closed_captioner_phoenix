defmodule Zoom.CaptionsProvider do
  @callback send_captions_to(String.t(), String.t(), Zoom.Params.t()) ::
              {:ok, map()} | {:error, term()}
end
