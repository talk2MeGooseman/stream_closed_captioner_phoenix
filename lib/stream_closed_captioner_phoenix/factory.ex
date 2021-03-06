defmodule StreamClosedCaptionerPhoenix.Factory do
  use ExMachina.Ecto, repo: StreamClosedCaptionerPhoenix.Repo

  def user_factory do
    %StreamClosedCaptionerPhoenix.Accounts.User{
      email: sequence(:email, &"email-#{&1}@example.com"),
      encrypted_password: "hello world!",
      sign_in_count: 0,
      uid: sequence(:uid, &"12345#{&1}"),
      username: "talk2megooseman",
      login: "talk2megooseman",
      stream_settings: build(:stream_settings),
      bits_balance: build(:bits_balance)
    }
  end

  def bits_balance_debit_factory do
    %StreamClosedCaptionerPhoenix.Bits.BitsBalanceDebit{
      amount: 500
    }
  end

  def bits_balance_factory do
    %StreamClosedCaptionerPhoenix.Bits.BitsBalance{
      balance: 0
    }
  end

  def bits_transaction_factory do
    %StreamClosedCaptionerPhoenix.Bits.BitsTransaction{
      amount: 500,
      purchaser_uid: "12345",
      sku: "sku500",
      transaction_id: "12d22",
      time: ~N[2010-04-17 14:00:00]
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
