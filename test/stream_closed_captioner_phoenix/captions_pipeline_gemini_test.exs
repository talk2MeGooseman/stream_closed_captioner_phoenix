defmodule StreamClosedCaptionerPhoenix.CaptionsPipelineGeminiTest do
  # async: false because FunWithFlags keeps flag state in a shared in-memory cache.
  use StreamClosedCaptionerPhoenix.DataCase, async: false

  import Mox
  import StreamClosedCaptionerPhoenix.Factory

  alias StreamClosedCaptionerPhoenix.CaptionsPipeline

  setup :verify_on_exit!

  setup do
    FunWithFlags.disable(:gemini_translations)
    on_exit(fn -> FunWithFlags.disable(:gemini_translations) end)
    :ok
  end

  describe "pipeline_to(:twitch) with :gemini_translations flag enabled" do
    test "routes through Gemini when the flag is enabled for the user" do
      user =
        insert(:user,
          bits_balance: build(:bits_balance, balance: 0, user: nil),
          translate_languages: [build(:translate_language, language: "es")]
        )

      insert(:bits_balance_debit, user: user)
      FunWithFlags.enable(:gemini_translations, for_actor: user)

      Gemini.MockCognitive
      |> expect(:translate, fn _from, _to, _text ->
        {:ok,
         Azure.Cognitive.Translations.new(%{
           translations: [%{"text" => "Hola (gemini)", "to" => "es"}]
         })}
      end)

      result =
        CaptionsPipeline.pipeline_to(:twitch, user, %{
          "interim" => "",
          "final" => "Hello",
          "session" => "abc"
        })

      assert {:ok,
              %Twitch.Extension.CaptionsPayload{
                translations: %{
                  "es" => %Azure.Cognitive.Translation{text: "Hola (gemini)", name: "Spanish"}
                }
              }} = result
    end
  end
end
