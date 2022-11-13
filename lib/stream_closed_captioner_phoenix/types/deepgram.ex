defmodule StreamClosedCaptionerPhoenix.Types.DeepgramAlternative do
  defstruct confidence: 0,
            transcript: nil

  use ExConstructor
end

defmodule StreamClosedCaptionerPhoenix.Types.DeepgramChannel do
  alias StreamClosedCaptionerPhoenix.Types.DeepgramAlternative
  defstruct alternatives: []

  use ExConstructor

  def new(data, args \\ []) do
    res = super(data, args)

    %{
      res
      | alternatives:
          Enum.map(
            res.alternatives,
            &DeepgramAlternative.new/1
          )
    }
  end
end

defmodule StreamClosedCaptionerPhoenix.DeepgramResponse do
  alias StreamClosedCaptionerPhoenix.Types.DeepgramChannel

  defstruct duration: 0,
            start: nil,
            is_final: nil,
            speech_final: nil,
            channel: %{}

  use ExConstructor

  def new(data, args \\ []) do
    res = super(data, args)

    %{res | channel: DeepgramChannel.new(res.channel)}
  end
end
