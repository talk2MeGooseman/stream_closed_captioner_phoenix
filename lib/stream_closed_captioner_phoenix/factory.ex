defmodule StreamClosedCaptionerPhoenix.Factory do
  use ExMachina.Ecto, repo: StreamClosedCaptionerPhoenix.Repo

  def user_factory do
    %StreamClosedCaptionerPhoenix.Accounts.User{
      email: sequence(:email, &"email-#{&1}@example.com"),
      password: "hello world!",
      # role: sequence(:role, ["admin", "user", "other"]),
    }
  end

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
