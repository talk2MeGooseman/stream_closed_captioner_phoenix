defmodule StreamClosedCaptionerPhoenix.CaptionsPipeline.Profanity do
  alias StreamClosedCaptionerPhoenix.Settings.StreamSettings

  file = Path.join([__DIR__, "..", "..", "..", "config", "profanity", "english.txt"])
  strip_quotes = fn word -> String.replace(word, ~r/^"\s*|\s*"$/, "") end

  @default_words File.read!(file)
                 |> String.split("\n")
                 |> Enum.map(strip_quotes)

  @doc """
  Censors profantiy using global configuration if the user has filter_profanity set to true on their StreamSettings.

  ## Examples

      iex> StreamClosedCaptionerPhoenix.CaptionsPipeline.Profanity.maybe_additional_censoring(%StreamClosedCaptionerPhoenix.Settings.StreamSettings{filter_profanity: true}, "Wow OMERGUDLUL123")
      "Wow *************"

      iex> StreamClosedCaptionerPhoenix.CaptionsPipeline.Profanity.maybe_additional_censoring(%StreamClosedCaptionerPhoenix.Settings.StreamSettings{filter_profanity: false}, "Wow OMERGUDLUL123")
      "Wow OMERGUDLUL123"
  """
  @spec maybe_additional_censoring(StreamingSettings.t(), String.t()) :: String.t()
  def maybe_additional_censoring(%StreamSettings{filter_profanity: filter_profanity}, text)
      when filter_profanity == false,
      do: text

  def maybe_additional_censoring(
        %StreamSettings{filter_profanity: filter_profanity},
        text
      )
      when filter_profanity == true do
    blocklist_config = create_blocklist_config(@default_words)
    Expletive.sanitize(text, blocklist_config, :stars)
  end

  @doc """
  Censors out words from the user's blocklist.

  ## Examples

      iex> StreamClosedCaptionerPhoenix.CaptionsPipeline.Profanity.censor_from_blocklist(%StreamClosedCaptionerPhoenix.Settings.StreamSettings{blocklist: ["poopy"]}, "you're a poopy head")
      "you're a ***** head"

      iex> StreamClosedCaptionerPhoenix.CaptionsPipeline.Profanity.censor_from_blocklist(%StreamClosedCaptionerPhoenix.Settings.StreamSettings{blocklist: []}, "you're a poopy head")
      "you're a poopy head"

      iex> StreamClosedCaptionerPhoenix.CaptionsPipeline.Profanity.censor_from_blocklist(%StreamClosedCaptionerPhoenix.Settings.StreamSettings{blocklist: nil}, "you're a poopy head")
      "you're a poopy head"
  """

  @spec censor_from_blocklist(StreamingSettings.t(), String.t()) :: String.t()
  def censor_from_blocklist(%StreamSettings{blocklist: blocklist}, text) do
    blocklist_config = create_blocklist_config(blocklist)
    Expletive.sanitize(text, blocklist_config, :stars)
  end

  defp create_blocklist_config(blocklist) when is_list(blocklist) do
    Expletive.configure(blacklist: blocklist)
  end

  defp create_blocklist_config(nil), do: Expletive.configure(blacklist: [])
end
