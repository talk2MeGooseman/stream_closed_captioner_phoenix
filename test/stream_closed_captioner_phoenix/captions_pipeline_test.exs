defmodule StreamClosedCaptionerPhoenix.CaptionsPipelineTest do
  use ExUnit.Case, async: true
  import StreamClosedCaptionerPhoenix.Factory

  doctest StreamClosedCaptionerPhoenix.CaptionsPipeline
  alias StreamClosedCaptionerPhoenix.CaptionsPipeline

  @azure_success_response [
    %{
      detectedLanguage: %{
        language: "en",
        score: 1.0
      },
      translations: [
        %{
          text: "Hola",
          to: "es"
        }
      ]
    }
  ]

  describe "maybe_translate/2" do
    @tag :skip
    test "will translate text if user at least 500 balance" do
      bits_balance = insert(:bits_balance, balance: 500)

      assert %{} == CaptionsPipeline.maybe_translate(bits_balance.user, "Hello")
    end
  end
end
