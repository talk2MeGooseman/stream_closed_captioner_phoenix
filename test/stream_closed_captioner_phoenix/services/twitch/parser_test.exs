defmodule Twitch.ParserTest do
  use ExUnit.Case, async: true

  alias Twitch.Parser

  describe "parse/1" do
    test "decodes a 200 body into {:ok, decoded}" do
      assert {:ok, %{"a" => 1}} = Parser.parse({:ok, %{status: 200, body: ~s({"a":1})}})
    end

    test "decodes a 201 body into {:ok, decoded}" do
      assert {:ok, %{"a" => 1}} = Parser.parse({:ok, %{status: 201, body: ~s({"a":1})}})
    end

    test "matches a %Req.Response{} struct the same as a plain map" do
      assert {:ok, %{"ok" => true}} =
               Parser.parse({:ok, %Req.Response{status: 200, body: ~s({"ok":true})}})
    end

    test "returns {:error, {:json_decode, _}} for an invalid 2xx body" do
      assert {:error, {:json_decode, %Jason.DecodeError{}}} =
               Parser.parse({:ok, %{status: 200, body: "<html>nope</html>"}})
    end

    test "returns {:error, decoded, status} for a non-2xx JSON body" do
      assert {:error, %{"message" => "bad"}, 400} =
               Parser.parse({:ok, %{status: 400, body: ~s({"message":"bad"})}})
    end

    test "returns {:error, raw_body, status} when a non-2xx body is not JSON" do
      assert {:error, "boom", 500} = Parser.parse({:ok, %{status: 500, body: "boom"}})
    end

    test "passes a transport error through as {:error, %{reason: reason}}" do
      assert {:error, %{reason: :timeout}} = Parser.parse({:error, %{reason: :timeout}})
    end

    test "returns unmatched input unchanged" do
      assert :anything = Parser.parse(:anything)
    end
  end
end
