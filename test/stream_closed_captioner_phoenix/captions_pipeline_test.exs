defmodule StreamClosedCaptionerPhoenix.CaptionsPipelineTest do
  import StreamClosedCaptionerPhoenix.Factory
  use StreamClosedCaptionerPhoenix.DataCase, async: true

  import Mox

  # Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  alias StreamClosedCaptionerPhoenix.CaptionsPipeline

  describe "CaptionsPipeline" do
    test "it successfully sends regular sentence to Twitch" do
      user = insert(:user)

      result =
        CaptionsPipeline.pipeline_to(:twitch, user, %{
          "interim" => "Hello",
          "final" => "",
          "session" => "disf12f3"
        })

      assert result ==
               {:ok,
                %Twitch.Extension.CaptionsPayload{
                  delay: 0,
                  final: "",
                  interim: "Hello",
                  translations: nil
                }}
    end

    test "when user has enough bits, activates translations and debits amount" do
      user = insert(:user, bits_balance: build(:bits_balance, balance: 500))

      Twitch.MockExtension
      |> expect(:send_pubsub_message_for, fn _creds, _channel, _message ->
        {:ok, %HTTPoison.Response{status_code: 204}}
      end)

      Azure.MockCognitive
      |> expect(:translate, fn _from_language, _to_languages, _text ->
        Azure.Cognitive.Translations.new(%{translations: [%{text: "Hola", to: "es"}]})
      end)

      result =
        CaptionsPipeline.pipeline_to(:twitch, user, %{
          "interim" => "",
          "final" => "Hello",
          "session" => "disf12f3"
        })

      assert result ==
               {:ok,
                %Twitch.Extension.CaptionsPayload{
                  delay: 0,
                  final: "Hello",
                  interim: "",
                  translations: %{
                    "es" => %Azure.Cognitive.Translation{text: "Hola", name: "Spanish"}
                  }
                }}

      assert %{balance: 0} = StreamClosedCaptionerPhoenix.Bits.get_bits_balance!(user)
    end

    test "when pirate mode is active, translates english to pirate" do
      user = insert(:user, stream_settings: build(:stream_settings, pirate_mode: true))

      result =
        CaptionsPipeline.pipeline_to(:twitch, user, %{
          "interim" => "Hello",
          "final" => "Friend",
          "session" => "disf12f3"
        })

      assert result ==
               {:ok,
                %Twitch.Extension.CaptionsPayload{
                  delay: 0,
                  final: "Matey",
                  interim: "Ahoy",
                  translations: nil
                }}
    end

    test "when a user has filter_profanity true and blocklist words, it filters out those words" do
      user =
        insert(:user,
          stream_settings: build(:stream_settings, filter_profanity: true, blocklist: ["poopy"])
        )

      result =
        CaptionsPipeline.pipeline_to(:twitch, user, %{
          "interim" => "Hello poopy head",
          "final" => "Friend",
          "session" => "disf12f3"
        })

      assert result ==
               {:ok,
                %Twitch.Extension.CaptionsPayload{
                  delay: 0,
                  interim: "Hello ***** head",
                  final: "Friend",
                  translations: nil
                }}
    end
  end
end
