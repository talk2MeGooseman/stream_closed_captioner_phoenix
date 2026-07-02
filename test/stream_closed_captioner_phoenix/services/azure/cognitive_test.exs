defmodule Azure.CognitiveTest do
  use ExUnit.Case, async: false

  import Plug.Conn

  alias Azure.Cognitive.Translation
  alias Azure.Cognitive.Translations

  describe "endpoint/0" do
    test "defaults to the production Azure Translator endpoint when no override is configured" do
      assert Azure.Cognitive.endpoint() ==
               "https://api.cognitive.microsofttranslator.com/translate"
    end
  end

  describe "Translation.new/1" do
    test "sets text and looks up name from translatable_languages for a known code" do
      translation = Translation.new(%{"to" => "es", "text" => "Hola"})

      assert %Translation{text: "Hola", name: "Spanish"} = translation
    end

    test "returns name: nil when the language code is not in translatable_languages" do
      translation = Translation.new(%{"to" => "xx", "text" => "???"})

      assert %Translation{text: "???", name: nil} = translation
    end
  end

  describe "Translations.new/1" do
    test "builds a map keyed by language code from a multi-entry translations list" do
      translations =
        Translations.new(%{
          "translations" => [
            %{"to" => "es", "text" => "Hola"},
            %{"to" => "fr", "text" => "Bonjour"}
          ]
        })

      assert %Translations{
               translations: %{
                 "es" => %Translation{text: "Hola", name: "Spanish"},
                 "fr" => %Translation{text: "Bonjour", name: "French"}
               }
             } = translations
    end

    test "returns an empty map for an empty translations list" do
      translations = Translations.new(%{"translations" => []})

      assert %Translations{translations: %{}} = translations
    end

    test "collapses an entry missing the \"to\" key under a nil map key" do
      translations =
        Translations.new(%{
          "translations" => [%{"text" => "no code here"}]
        })

      assert %Translations{translations: %{nil => %Translation{text: "no code here"}}} =
               translations
    end
  end

  describe "translate/3 — short-circuits" do
    test "returns empty translations without an HTTP call when the only target matches the source language" do
      assert {:ok, %Translations{translations: translations}} =
               Azure.Cognitive.translate("en-US", ["en"], "Hello")

      assert translations == %{}
    end

    test "returns empty translations without an HTTP call for empty to_languages" do
      assert {:ok, %Translations{translations: translations}} =
               Azure.Cognitive.translate("en", [], "Hello")

      assert translations == %{}
    end
  end

  describe "translate/3 — HTTP" do
    setup do
      bypass = Bypass.open()

      System.put_env("COGNITIVE_SERVICE_KEY", "test-azure-key")

      Application.put_env(
        :stream_closed_captioner_phoenix,
        :azure_endpoint,
        "http://localhost:#{bypass.port}/translate"
      )

      on_exit(fn ->
        System.delete_env("COGNITIVE_SERVICE_KEY")
        Application.delete_env(:stream_closed_captioner_phoenix, :azure_endpoint)
      end)

      {:ok, bypass: bypass}
    end

    test "parses a well-formed response into a Translations struct keyed by language code", %{
      bypass: bypass
    } do
      response_body =
        Jason.encode!([
          %{
            "translations" => [
              %{"to" => "es", "text" => "Hola"},
              %{"to" => "fr", "text" => "Bonjour"}
            ]
          }
        ])

      Bypass.expect_once(bypass, "POST", "/translate", fn conn ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, response_body)
      end)

      assert {:ok, %Translations{translations: translations}} =
               Azure.Cognitive.translate("en", ["es", "fr"], "Hello")

      assert %Translation{text: "Hola", name: "Spanish"} = translations["es"]
      assert %Translation{text: "Bonjour", name: "French"} = translations["fr"]
    end

    test "sends the API key as a header, never in the query string", %{bypass: bypass} do
      response_body = Jason.encode!([%{"translations" => [%{"to" => "es", "text" => "Hola"}]}])

      Bypass.expect_once(bypass, "POST", "/translate", fn conn ->
        assert [api_key_header] = get_req_header(conn, "ocp-apim-subscription-key")
        assert api_key_header == "test-azure-key"
        refute conn.query_string =~ "test-azure-key"
        refute conn.query_string =~ "Ocp-Apim"

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, response_body)
      end)

      assert {:ok, _translations} = Azure.Cognitive.translate("en", ["es"], "Hello")
    end

    test "returns :unexpected_json when the top-level JSON is not a single-element list", %{
      bypass: bypass
    } do
      Bypass.expect_once(bypass, "POST", "/translate", fn conn ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{"error" => "nope"}))
      end)

      assert {:error, {:unexpected_json, _other}} =
               Azure.Cognitive.translate("en", ["es"], "Hello")
    end

    test "returns :json_decode when the response body is not valid JSON", %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/translate", fn conn ->
        conn
        |> put_resp_content_type("text/html")
        |> send_resp(200, "<html>gateway error</html>")
      end)

      assert {:error, {:json_decode, %Jason.DecodeError{}}} =
               Azure.Cognitive.translate("en", ["es"], "Hello")
    end

    test "returns :http error when the server is unreachable", %{bypass: bypass} do
      Bypass.down(bypass)

      assert {:error, {:http, :econnrefused}} = Azure.Cognitive.translate("en", ["es"], "Hello")
    end

    test "omits the source language from the to= params on a partial match", %{bypass: bypass} do
      response_body = Jason.encode!([%{"translations" => [%{"to" => "es", "text" => "Hola"}]}])

      Bypass.expect_once(bypass, "POST", "/translate", fn conn ->
        query = URI.decode_query(conn.query_string)
        assert query["to"] == "es"

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, response_body)
      end)

      assert {:ok, _translations} = Azure.Cognitive.translate("en", ["es", "en"], "Hello")
    end

    test "keeps a target language whose casing differs from the source (case-sensitive match)", %{
      bypass: bypass
    } do
      response_body = Jason.encode!([%{"translations" => [%{"to" => "EN", "text" => "Hello"}]}])

      Bypass.expect_once(bypass, "POST", "/translate", fn conn ->
        assert conn.query_string =~ "to=EN"

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, response_body)
      end)

      assert {:ok, _translations} = Azure.Cognitive.translate("en-US", ["EN"], "Hello")
    end
  end
end
