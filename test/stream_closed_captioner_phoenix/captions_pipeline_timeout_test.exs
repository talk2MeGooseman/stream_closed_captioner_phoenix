defmodule StreamClosedCaptionerPhoenix.CaptionsPipelineTimeoutTest do
  # async: false because Application.put_env below mutates global VM config;
  # running concurrently with async tests that pass through Task.yield would
  # cause them to inherit the 100ms window and spuriously report :timeout.
  use StreamClosedCaptionerPhoenix.DataCase, async: false

  import Mox
  import StreamClosedCaptionerPhoenix.Factory

  alias StreamClosedCaptionerPhoenix.CaptionsPipeline

  setup :verify_on_exit!

  setup do
    previous = Application.get_env(:stream_closed_captioner_phoenix, :translation_timeout)
    Application.put_env(:stream_closed_captioner_phoenix, :translation_timeout, 100)

    on_exit(fn ->
      if previous do
        Application.put_env(:stream_closed_captioner_phoenix, :translation_timeout, previous)
      else
        Application.delete_env(:stream_closed_captioner_phoenix, :translation_timeout)
      end
    end)

    :ok
  end

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
        })

      assert {:ok, %Twitch.Extension.CaptionsPayload{translation_error: :timeout}} = result
    end
  end
end
