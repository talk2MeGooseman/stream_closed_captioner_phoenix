defmodule Zoom.CaptionsProvider do
  @callback send_captions_to(String.t(), String.t(), Zoom.Params.t()) ::
              {:ok, %{status: non_neg_integer(), body: binary()}} | {:error, term()}
end
