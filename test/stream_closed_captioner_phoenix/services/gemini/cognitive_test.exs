defmodule Gemini.CognitiveTest do
  use ExUnit.Case, async: true

  alias Azure.Cognitive.Translation
  alias Azure.Cognitive.Translations

  describe "parse_response_body/1" do
    test "parses a well-formed Gemini response into Translations struct keyed by language code" do
      inner_json =
        Jason.encode!(%{
          translations: [
            %{"to" => "es", "text" => "Hola"},
            %{"to" => "fr", "text" => "Bonjour"}
          ]
        })

      raw_body =
        Jason.encode!(%{
          "candidates" => [
            %{"content" => %{"parts" => [%{"text" => inner_json}]}}
          ]
        })

      assert {:ok, %Translations{translations: translations}} =
               Gemini.Cognitive.parse_response_body(raw_body)

      assert %Translation{text: "Hola", name: "Spanish"} = translations["es"]
      assert %Translation{text: "Bonjour", name: "French"} = translations["fr"]
    end

    test "returns :unexpected_json when candidates list is missing" do
      raw_body = Jason.encode!(%{"promptFeedback" => %{"blockReason" => "SAFETY"}})

      assert {:error, {:unexpected_json, _}} =
               Gemini.Cognitive.parse_response_body(raw_body)
    end

    test "returns :unexpected_json when candidates list is empty" do
      raw_body = Jason.encode!(%{"candidates" => []})

      assert {:error, {:unexpected_json, _}} =
               Gemini.Cognitive.parse_response_body(raw_body)
    end

    test "returns :unexpected_json when candidate parts are missing" do
      raw_body =
        Jason.encode!(%{
          "candidates" => [%{"content" => %{"parts" => []}}]
        })

      assert {:error, {:unexpected_json, _}} =
               Gemini.Cognitive.parse_response_body(raw_body)
    end

    test "returns :json_decode when inner text is not valid JSON" do
      raw_body =
        Jason.encode!(%{
          "candidates" => [
            %{"content" => %{"parts" => [%{"text" => "not json at all"}]}}
          ]
        })

      assert {:error, {:json_decode, %Jason.DecodeError{}}} =
               Gemini.Cognitive.parse_response_body(raw_body)
    end

    test "returns :json_decode when outer body is not valid JSON" do
      assert {:error, {:json_decode, %Jason.DecodeError{}}} =
               Gemini.Cognitive.parse_response_body("<html>oops</html>")
    end

    test "returns :unexpected_json when inner payload is missing translations key" do
      inner_json = Jason.encode!(%{"unexpected" => "shape"})

      raw_body =
        Jason.encode!(%{
          "candidates" => [
            %{"content" => %{"parts" => [%{"text" => inner_json}]}}
          ]
        })

      assert {:error, {:unexpected_json, _}} =
               Gemini.Cognitive.parse_response_body(raw_body)
    end
  end

  describe "translate/3 — short-circuits" do
    test "returns empty translations struct when to_languages filter yields nothing" do
      assert {:ok, %Translations{translations: translations}} =
               Gemini.Cognitive.translate("en", ["en"], "Hello")

      assert translations == %{}
    end

    test "returns empty translations struct for empty to_languages" do
      assert {:ok, %Translations{translations: translations}} =
               Gemini.Cognitive.translate("en", [], "Hello")

      assert translations == %{}
    end
  end
end
