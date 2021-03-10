defmodule StreamClosedCaptionerPhoenix.Settings.TranslateLanguageAdmin do
  alias StreamClosedCaptionerPhoenix.{Accounts, Settings}

  def get_user(%{user_id: id}) do
    id
    |> Accounts.get_user!()
    |> Map.get(:username)
  end

  def index(_) do
    [
      user_id: %{name: "User", value: fn p -> get_user(p) end},
      language: nil
    ]
  end

  def form_fields(_) do
    [
      user_id: %{update: :readonly},
      language: %{choices: Settings.translateable_language_list()}
    ]
  end
end
