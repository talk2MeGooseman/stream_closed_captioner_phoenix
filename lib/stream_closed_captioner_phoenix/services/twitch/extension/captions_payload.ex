defmodule Twitch.Extension.CaptionsPayload do
  @derive Jason.Encoder
  @type t :: %__MODULE__{
          interim: String.t(),
          final: String.t(),
          delay: number(),
          translations: map() | nil,
          translation_error: atom() | nil
        }
  defstruct interim: "", final: "", delay: 0, translations: nil, translation_error: nil

  use ExConstructor
end
