defmodule StreamClosedCaptionerPhoenix.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `StreamClosedCaptionerPhoenix.Accounts` context.
  """

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def valid_user_password, do: "hello world!"

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(%{
        email: unique_user_email(),
        password: valid_user_password()
      })
      |> StreamClosedCaptionerPhoenix.Accounts.register_user()

    user
  end

  def transcript_fixture(attrs \\ %{}) do
    {:ok, transcript} =
      attrs
      |> Enum.into(%{
        name: "some name",
        session: "some session",
        user_id: user_fixture().id
      })
      |> StreamClosedCaptionerPhoenix.Accounts.create_transcript()

    transcript
  end

  def message_fixture(attrs \\ %{}) do
    {:ok, message} =
      attrs
      |> Enum.into(
        %{
          text: "some text",
          transcript_id: transcript_fixture().id
        }
      )
      |> StreamClosedCaptionerPhoenix.Accounts.create_message()

    message
  end

  def extract_user_token(fun) do
    {:ok, captured} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token, _] = String.split(captured.body, "[TOKEN]")
    token
  end
end
