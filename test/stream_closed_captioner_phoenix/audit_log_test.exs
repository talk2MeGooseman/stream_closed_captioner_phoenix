defmodule StreamClosedCaptionerPhoenix.AuditLogTest do
  use ExUnit.Case, async: false

  import StreamClosedCaptionerPhoenix.AuditHelpers

  alias StreamClosedCaptionerPhoenix.AuditLog
  alias StreamClosedCaptionerPhoenix.Accounts.User

  describe "redact_deep/1 (via info/2 telemetry metadata)" do
    test "strips redacted string keys from a flat map" do
      capture_audit_events(fn ->
        AuditLog.info("test.event", %{"access_token" => "secret", user_id: 1})
      end)

      assert_receive {:audit_event, _measurements, metadata}
      assert metadata.user_id == 1
      refute Map.has_key?(metadata, "access_token")
    end

    test "strips redacted atom keys from a flat map" do
      capture_audit_events(fn ->
        AuditLog.info("test.event", %{
          user_id: 1,
          password: "secret",
          azure_service_key: "abc123"
        })
      end)

      assert_receive {:audit_event, _measurements, metadata}
      assert metadata.user_id == 1
      refute Map.has_key?(metadata, :password)
      refute Map.has_key?(metadata, :azure_service_key)
    end

    test "strips both atom and string keys for the same logical field in one map" do
      capture_audit_events(fn ->
        AuditLog.info("test.event", %{"password" => "b", password: "a"})
      end)

      assert_receive {:audit_event, _measurements, metadata}
      refute Map.has_key?(metadata, :password)
      refute Map.has_key?(metadata, "password")
    end

    test "recurses into nested maps, stripping the nested sensitive key" do
      capture_audit_events(fn ->
        AuditLog.info("test.event", %{user: %{password: "x"}})
      end)

      assert_receive {:audit_event, _measurements, metadata}
      assert Map.has_key?(metadata, :user)
      refute Map.has_key?(metadata.user, :password)
    end

    test "keyword list values: the redacted entry is dropped entirely (deletion, same as flat maps)" do
      capture_audit_events(fn ->
        AuditLog.info("test.event", %{opts: [password: "x", safe: "y"]})
      end)

      assert_receive {:audit_event, _measurements, metadata}
      refute Keyword.has_key?(metadata.opts, :password)
      assert Keyword.get(metadata.opts, :safe) == "y"
    end

    test "non-keyword list of 2-tuples with string keys: the entry is kept but its value is masked" do
      capture_audit_events(fn ->
        AuditLog.info("test.event", %{opts: [{"password", "x"}, {"safe", "y"}]})
      end)

      assert_receive {:audit_event, _measurements, metadata}
      assert {"password", "[REDACTED]"} in metadata.opts
      assert {"safe", "y"} in metadata.opts
    end

    test "tuples and lists that aren't key-value shaped pass through without crashing" do
      capture_audit_events(fn ->
        AuditLog.info("test.event", %{data: {1, 2, 3}, list: [1, 2, 3]})
      end)

      assert_receive {:audit_event, _measurements, metadata}
      assert metadata.data == {1, 2, 3}
      assert metadata.list == [1, 2, 3]
    end

    test "non-sensitive values are left untouched, including a value equal to a redacted key name" do
      capture_audit_events(fn ->
        AuditLog.info("test.event", %{note: "password"})
      end)

      assert_receive {:audit_event, _measurements, metadata}
      assert metadata.note == "password"
    end

    test "near-miss keys are not redacted (exact-match only)" do
      capture_audit_events(fn ->
        AuditLog.info("test.event", %{"twitch_access_token" => "secret"})
      end)

      assert_receive {:audit_event, _measurements, metadata}
      assert metadata["twitch_access_token"] == "secret"
    end

    test "a struct value nested in metadata currently crashes (known limitation; no current call site does this)" do
      user = %User{password: "secret", access_token: "tok", refresh_token: "reftok"}

      # redact_deep/1's map clause calls Map.new/2 on the value, which raises for
      # structs (Elixir no longer treats structs as plain enumerable maps here).
      # No AuditLog.info/2 or warn/2 call site today passes a struct as a metadata
      # value, so this isn't reachable in production, but it's a real crash risk if
      # one ever does. Locked in as a regression test rather than silently "fixed"
      # here, since fixing AuditLog is out of scope for this test-only issue.
      assert_raise Protocol.UndefinedError, fn ->
        capture_audit_events(fn ->
          AuditLog.info("test.event", %{user: user})
        end)
      end
    end

    test "empty map and empty nested list don't crash" do
      capture_audit_events(fn ->
        AuditLog.info("test.event", %{})
      end)

      assert_receive {:audit_event, _measurements, metadata}
      assert metadata.event == "test.event"

      capture_audit_events(fn ->
        AuditLog.info("test.event", %{data: []})
      end)

      assert_receive {:audit_event, _measurements, metadata}
      assert metadata.data == []
    end
  end

  describe "format_reason/1" do
    test "returns atoms unchanged, including nil and booleans" do
      assert AuditLog.format_reason(:some_atom) == :some_atom
      assert AuditLog.format_reason(nil) == nil
      assert AuditLog.format_reason(true) == true
      assert AuditLog.format_reason(false) == false
    end

    test "traverses an %Ecto.Changeset{}'s errors" do
      changeset =
        User.password_changeset(%User{}, %{password: "short", password_confirmation: "x"})

      refute changeset.valid?

      assert AuditLog.format_reason(changeset) == %{
               password: ["should be at least %{count} character(s)"],
               password_confirmation: ["does not match password"]
             }
    end

    test "returns binaries unchanged" do
      assert AuditLog.format_reason("already a string") == "already a string"
    end

    test "falls back to inspect/2 for any other type" do
      assert AuditLog.format_reason({:some, :tuple}) == inspect({:some, :tuple}, limit: 5, printable_limit: 100)
    end
  end
end
