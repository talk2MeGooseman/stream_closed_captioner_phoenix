defmodule Twitch.Extension.CaptionsPayload do
  @derive Jason.Encoder
  @type t :: %__MODULE__{
          interim: String.t(),
          final: String.t(),
          delay: float(),
          translations: map()
        }
  defstruct interim: "", final: "", delay: 0, translations: nil

  use ExConstructor
end
