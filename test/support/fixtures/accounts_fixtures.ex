defmodule StreamClosedCaptionerPhoenix.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `StreamClosedCaptionerPhoenix.Accounts` context.
  """

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def valid_user_password, do: "hello world!"

  def user_fixture(attrs \\ %{}) do
    {:ok, %{user: user}} =
      attrs
      |> Enum.into(%{
        email: unique_user_email(),
        password: valid_user_password()
      })
      |> StreamClosedCaptionerPhoenix.Accounts.register_user()

    user
  end

  def extract_user_token(fun) do
    captured = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token, _] = String.split(captured.text_body, "[TOKEN]")
    token
  end
end
