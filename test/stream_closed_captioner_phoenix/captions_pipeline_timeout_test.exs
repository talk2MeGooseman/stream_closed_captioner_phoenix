defmodule StreamClosedCaptionerPhoenix.CaptionsPipelineTimeoutTest do
  # async: false required because set_mox_global is needed to allow the Task spawned
  # inside do_pipeline_twitch to call Azure.MockCognitive from a different process.
  use StreamClosedCaptionerPhoenix.DataCase, async: false

  import Mox
  import StreamClosedCaptionerPhoenix.Factory

  alias StreamClosedCaptionerPhoenix.CaptionsPipeline

  setup :set_mox_global
  setup :verify_on_exit!

  describe "pipeline_to(:twitch) translation timeout" do
    test "returns payload with translation_error: :timeout when translation exceeds the timeout" do
      user =
        insert(:user,
          bits_balance: build(:bits_balance, balance: 0, user: nil),
          translate_languages: [build(:translate_language, language: "es")]
        )

      insert(:bits_balance_debit, user: user)

      Azure.MockCognitive
      |> expect(:translate, fn _from, _to, _text ->
        Process.sleep(:infinity)
      end)

      result =
        CaptionsPipeline.pipeline_to(:twitch, user, %{
          "interim" => "",
          "final" => "Hello",
          "session" => "abc"
        }, 100)

      assert {:ok, %Twitch.Extension.CaptionsPayload{translation_error: :timeout}} = result
    end
  end
end
