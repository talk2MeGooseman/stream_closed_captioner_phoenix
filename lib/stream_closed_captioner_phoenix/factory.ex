defmodule StreamClosedCaptionerPhoenix.Factory do
  @moduledoc """
  ExMachina factory for test data.

  ## `insert(:user)` creates 3 database records

  The `user_factory` automatically builds and inserts associated `stream_settings`
  and `bits_balance` records. Calling `insert(:user)` creates:

    - 1 `users` row
    - 1 `stream_settings` row (linked to the user)
    - 1 `bits_balance` row (linked to the user)

  To opt out of an association, pass `nil` as the value:

      insert(:user, bits_balance: nil)    # no bits_balance created
      insert(:user, stream_settings: nil) # no stream_settings created

  To update an association on an existing user (e.g., to set a specific balance),
  update the existing associated record — do NOT insert a new one alongside the user:

      user = insert(:user)
      Repo.update!(BitsBalance.changeset(user.bits_balance, %{balance: 500}))

  ## Child factory defaults

  The `bits_balance`, `bits_balance_debit`, and `bits_transaction` factories
  each include a default user via the `bare_user_factory` — a user with no
  pre-built associations. Using `bare_user_factory` (rather than `user_factory`)
  breaks the cycle that would occur if child factories called the full
  `user_factory` (which itself embeds `bits_balance`). To override, pass
  `user:` explicitly or pass `user: nil` to clear it:

      insert(:bits_balance, user: some_user)
      build(:bits_balance, user: nil)
  """
  use ExMachina.Ecto, repo: StreamClosedCaptionerPhoenix.Repo

  def bare_user_factory do
    %StreamClosedCaptionerPhoenix.Accounts.User{
      email: sequence(:email, &"email-#{&1}@example.com"),
      encrypted_password: "hello world!",
      sign_in_count: 0,
      uid: sequence(:uid, &"12345#{&1}"),
      username: "talk2megooseman",
      login: "talk2megooseman"
    }
  end

  def user_factory do
    %StreamClosedCaptionerPhoenix.Accounts.User{
      email: sequence(:email, &"email-#{&1}@example.com"),
      encrypted_password: "hello world!",
      sign_in_count: 0,
      uid: sequence(:uid, &"12345#{&1}"),
      username: "talk2megooseman",
      login: "talk2megooseman",
      stream_settings: build(:stream_settings),
      bits_balance: build(:bits_balance, user: nil)
    }
  end

  def bits_balance_debit_factory do
    %StreamClosedCaptionerPhoenix.Bits.BitsBalanceDebit{
      amount: 500,
      user: build(:bare_user)
    }
  end

  def bits_balance_factory do
    %StreamClosedCaptionerPhoenix.Bits.BitsBalance{
      balance: 0,
      user: build(:bare_user)
    }
  end

  def bits_transaction_factory do
    %StreamClosedCaptionerPhoenix.Bits.BitsTransaction{
      amount: 500,
      purchaser_uid: "12345",
      sku: "sku500",
      transaction_id: "12d22",
      time: ~N[2010-04-17 14:00:00],
      user: build(:bare_user)
    }
  end

  def stream_settings_factory do
    %StreamClosedCaptionerPhoenix.Settings.StreamSettings{
      caption_delay: 0,
      language: "en-US"
    }
  end

  def translate_language_factory do
    %StreamClosedCaptionerPhoenix.Settings.TranslateLanguage{
      language: "en"
    }
  end

  def message_factory do
    %StreamClosedCaptionerPhoenix.Transcripts.Message{
      text: "Hello"
    }
  end

  def transcript_factory do
    %StreamClosedCaptionerPhoenix.Transcripts.Transcript{
      name: "Some Date",
      session: sequence(:session, &"abc#{&1}")
    }
  end

  # role: sequence(:role, ["admin", "user", "other"]),
  # def article_factory do
  #   title = sequence(:title, &"Use ExMachina! (Part #{&1})")
  #   # derived attribute
  #   slug = MyApp.Article.title_to_slug(title)
  #   %MyApp.Article{
  #     title: title,
  #     slug: slug,
  #     # associations are inserted when you call `insert`
  #     author: build(:user),
  #   }
  # end
end
