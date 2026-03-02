defmodule StreamClosedCaptionerPhoenix.CaptionsPipelineTest do
  import StreamClosedCaptionerPhoenix.Factory
  use StreamClosedCaptionerPhoenix.DataCase, async: true

  import Mox

  # Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  alias StreamClosedCaptionerPhoenix.CaptionsPipeline

  describe "pipeline_to(:default)" do
    test "it passes text through unchanged with default stream settings" do
      user = insert(:user)

      result =
        CaptionsPipeline.pipeline_to(:default, user, %{
          "interim" => "Hello",
          "final" => "World",
          "session" => "abc123"
        })

      assert result ==
               {:ok,
                %Twitch.Extension.CaptionsPayload{
                  delay: 0,
                  final: "World",
                  interim: "Hello",
                  translations: nil
                }}
    end

    test "when pirate mode is active, translates both interim and final" do
      user = insert(:user, stream_settings: build(:stream_settings, pirate_mode: true))

      result =
        CaptionsPipeline.pipeline_to(:default, user, %{
          "interim" => "Hello",
          "final" => "Friend",
          "session" => "abc123"
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

    test "when profanity filter is active with blocklist words, it filters those words" do
      user =
        insert(:user,
          stream_settings: build(:stream_settings, filter_profanity: true, blocklist: ["poopy"])
        )

      result =
        CaptionsPipeline.pipeline_to(:default, user, %{
          "interim" => "Hello poopy head",
          "final" => "Friend",
          "session" => "abc123"
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

    test "when user has enough bits, but hasnt selected a translate language, it wont translate" do
      user =
        insert(:user,
          bits_balance: build(:bits_balance, balance: 500),
          translate_languages: []
        )

      result =
        CaptionsPipeline.pipeline_to(:twitch, user, %{
          "interim" => "",
          "final" => "Hello",
          "session" => "disf12f3"
        })

      assert {:ok,
              %Twitch.Extension.CaptionsPayload{
                delay: 0,
                final: "Hello",
                interim: "",
                translations: nil
              }} == result

      assert %{balance: 500} = StreamClosedCaptionerPhoenix.Bits.get_bits_balance!(user)
    end

    test "when user has enough bits, activates translations and debits amount" do
      user =
        insert(:user,
          bits_balance: build(:bits_balance, balance: 500),
          translate_languages: [build(:translate_language, language: "es")]
        )

      Azure.MockCognitive
      |> expect(:translate, fn _from_language, _to_languages, _text ->
        Azure.Cognitive.Translations.new(%{translations: [%{"text" => "Hola", "to" => "es"}]})
      end)

      result =
        CaptionsPipeline.pipeline_to(:twitch, user, %{
          "interim" => "",
          "final" => "Hello",
          "session" => "disf12f3"
        })

      assert {:ok,
              %Twitch.Extension.CaptionsPayload{
                delay: 0,
                final: "Hello",
                interim: "",
                translations: %Azure.Cognitive.Translations{
                  translations: %{
                    "es" => %Azure.Cognitive.Translation{text: "Hola", name: "Spanish"}
                  }
                }
              }} == result

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

    test "when user has languages but insufficient bits balance, it won't translate" do
      user =
        insert(:user,
          bits_balance: build(:bits_balance, balance: 499),
          translate_languages: [build(:translate_language, language: "es")]
        )

      result =
        CaptionsPipeline.pipeline_to(:twitch, user, %{
          "interim" => "",
          "final" => "Hello",
          "session" => "disf12f3"
        })

      assert {:ok,
              %Twitch.Extension.CaptionsPayload{
                delay: 0,
                final: "Hello",
                interim: "",
                translations: nil
              }} == result

      assert %{balance: 499} = StreamClosedCaptionerPhoenix.Bits.get_bits_balance!(user)
    end

    test "when user already has an active translation debit, translates without debiting balance" do
      user =
        insert(:user,
          bits_balance: build(:bits_balance, balance: 0),
          translate_languages: [build(:translate_language, language: "es")]
        )

      insert(:bits_balance_debit, user: user)

      Azure.MockCognitive
      |> expect(:translate, fn _from_language, _to_languages, _text ->
        Azure.Cognitive.Translations.new(%{translations: [%{"text" => "Hola", "to" => "es"}]})
      end)

      result =
        CaptionsPipeline.pipeline_to(:twitch, user, %{
          "interim" => "",
          "final" => "Hello",
          "session" => "disf12f3"
        })

      assert {:ok,
              %Twitch.Extension.CaptionsPayload{
                delay: 0,
                final: "Hello",
                interim: "",
                translations: %{
                  "es" => %Azure.Cognitive.Translation{text: "Hola", name: "Spanish"}
                }
              }} == result

      # Balance should NOT be debited – the active debit record means translation was already paid
      assert %{balance: 0} = StreamClosedCaptionerPhoenix.Bits.get_bits_balance!(user)
    end
  end
end
