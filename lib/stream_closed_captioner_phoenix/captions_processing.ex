defmodule StreamClosedCaptionerPhoenix.CaptionsProcessing do
  file = Path.join([__DIR__, "..", "..", "config", "profanity", "english.txt"])
  strip_quotes = fn (word) -> String.replace(word, ~r/^"\s*|\s*"$/, "") end

  words =
    File.read!(file)
    |> String.split("\n")
    |> Enum.map(strip_quotes)

  @global_expletives_config Expletive.configure(blacklist: words)

  @doc """
  Censors profantiy using global configuration if the user has filter_profanity enabled on their StreamSettings.

  ## Examples

      iex> StreamClosedCaptionerPhoenix.CaptionsProcessing.filter_profanity(%{filter_profanity: true}, "Wow OMERGUDLUL123")
      "Wow *************"

      iex> StreamClosedCaptionerPhoenix.CaptionsProcessing.filter_profanity(%{filter_profanity: false}, "Wow OMERGUDLUL123")
      "Wow OMERGUDLUL123"
  """
  def filter_profanity(%{filter_profanity: filter_profanity}, text)
      when filter_profanity == false do
    text
  end

  def filter_profanity(%{filter_profanity: filter_profanity}, text) when filter_profanity do
    text |> Expletive.sanitize(@global_expletives_config, :stars)
  end
end
