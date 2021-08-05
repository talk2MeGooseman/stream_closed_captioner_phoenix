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

      iex> StreamClosedCaptionerPhoenix.CaptionsPipeline.Profanity.maybe_censor(%StreamClosedCaptionerPhoenix.Settings.StreamSettings{filter_profanity: true}, "Wow OMERGUDLUL123")
      "Wow *************"

      iex> StreamClosedCaptionerPhoenix.CaptionsPipeline.Profanity.maybe_censor(%StreamClosedCaptionerPhoenix.Settings.StreamSettings{filter_profanity: false}, "Wow OMERGUDLUL123")
      "Wow OMERGUDLUL123"
  """
  @spec maybe_censor(StreamingSettings.t(), String.t()) :: String.t()
  def maybe_censor(%StreamSettings{filter_profanity: filter_profanity}, text)
      when filter_profanity == false,
      do: text

  def maybe_censor(
        %StreamSettings{filter_profanity: filter_profanity, blocklist: blocklist},
        text
      )
      when filter_profanity == true do
    blocklist_config = create_blocklist_config(blocklist)
    Expletive.sanitize(text, blocklist_config, :stars)
  end

  defp create_blocklist_config([]), do: Expletive.configure(blacklist: @default_words)
  defp create_blocklist_config(nil), do: Expletive.configure(blacklist: @default_words)

  defp create_blocklist_config(user_list),
    do: Expletive.configure(blacklist: @default_words ++ user_list)
end
