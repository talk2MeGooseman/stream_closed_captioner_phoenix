defmodule StreamClosedCaptionerPhoenix.RateLimit do
  use Hammer, backend: :ets
end
