defmodule StreamClosedCaptionerPhoenix.CaptionsPipeline.ProfanityTest do
  use StreamClosedCaptionerPhoenix.DataCase, async: true
  # This runs the tests using the doc header on the function
  doctest StreamClosedCaptionerPhoenix.CaptionsPipeline.Profanity

  describe "maybe_censor/2" do
    test "censors out words from the users blocklist" do
      assert "you're a ***** head" =
               StreamClosedCaptionerPhoenix.CaptionsPipeline.Profanity.maybe_censor(
                 %StreamClosedCaptionerPhoenix.Settings.StreamSettings{
                   filter_profanity: true,
                   blocklist: ["poopy"]
                 },
                 "you're a poopy head"
               )
    end
  end
end
