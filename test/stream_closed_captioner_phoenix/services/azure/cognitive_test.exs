defmodule Azure.CognitiveTest do
  use ExUnit.Case, async: true
  
  import Mox
  
  alias Azure.Cognitive
  alias NewRelic.Instrumented.HTTPoison

  setup :verify_on_exit!

  describe "translate/4 with user key" do
    test "uses user provided key when given" do
      user_key = "user-provided-key-123"
      from_language = "en"
      to_languages = ["es"]
      text = "Hello"
      
      response_body = Jason.encode!([
        %{
          "translations" => [
            %{"text" => "Hola", "to" => "es"}
          ]
        }
      ])
      
      expect(Ecto.UUID, :generate, fn -> "some-uuid" end)
      expect(HTTPoison, :post!, fn url, body, headers ->
        # Verify user key is in headers
        {_, actual_key} = Enum.find(headers, fn {key, _} -> key == "Ocp-Apim-Subscription-Key" end)
        assert actual_key == user_key
        
        %{body: response_body}
      end)
      
      result = Cognitive.translate(from_language, to_languages, text, user_key)
      assert %Azure.Cognitive.Translations{} = result
    end

    test "uses system env key when user key is nil" do
      from_language = "en"
      to_languages = ["es"]
      text = "Hello"
      
      response_body = Jason.encode!([
        %{
          "translations" => [
            %{"text" => "Hola", "to" => "es"}
          ]
        }
      ])
      
      expect(Ecto.UUID, :generate, fn -> "some-uuid" end)
      expect(HTTPoison, :post!, fn url, body, headers ->
        # Verify system env key is used
        {_, actual_key} = Enum.find(headers, fn {key, _} -> key == "Ocp-Apim-Subscription-Key" end)
        assert actual_key == System.get_env("COGNITIVE_SERVICE_KEY")
        
        %{body: response_body}
      end)
      
      result = Cognitive.translate(from_language, to_languages, text, nil)
      assert %Azure.Cognitive.Translations{} = result
    end
  end
end