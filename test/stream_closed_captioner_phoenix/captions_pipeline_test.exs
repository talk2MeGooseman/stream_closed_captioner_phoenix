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

      Twitch.MockExtension
      |> expect(:send_pubsub_message_for, fn _creds, _channel, _message ->
        {:ok, %HTTPoison.Response{status_code: 204}}
      end)

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

    test "returns error if credentials are invalid" do
      user = insert(:user)

      Twitch.MockExtension
      |> expect(:send_pubsub_message_for, fn _creds, _channel, _message ->
        {:ok, %HTTPoison.Response{status_code: 400, body: "Bad Error"}}
      end)

      result =
        CaptionsPipeline.pipeline_to(:twitch, user, %{
          "interim" => "Hello",
          "final" => "",
          "session" => "disf12f3"
        })

      assert result == {:error, "Request was rejected"}
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
  end
end
