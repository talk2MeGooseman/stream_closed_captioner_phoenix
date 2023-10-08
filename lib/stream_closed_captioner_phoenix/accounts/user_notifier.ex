defmodule StreamClosedCaptionerPhoenix.Accounts.UserNotifier do
  import Bamboo.Email

  defp deliver(to, subject, body) do
    require Logger
    Logger.debug(body)

    new_email(
      to: to,
      from: "erik.guzman@guzman.codes",
      subject: subject,
      text_body: body
    )
    |> StreamClosedCaptionerPhoenix.Mailer.deliver_now()
  end

  @doc """
  Deliver instructions to confirm account.
  """
  def deliver_confirmation_instructions(user, url) do
    deliver(user.email, "Confirm your account", """

    ==============================

    Hi #{user.email},

    You can confirm your account by visiting the URL below:

    #{url}

    If you didn't create an account with us, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to reset a user password.
  """
  def deliver_reset_password_instructions(user, url) do
    deliver(user.email, "Stream CC Password Reset Instructions", """

    ==============================

    Hi #{user.email},

    You can reset your password by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to update a user email.
  """
  def deliver_update_email_instructions(user, url) do
    deliver(user.email, "Stream CC Update Email Instructions", """

    ==============================

    Hi #{user.email},

    You can change your email by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end
end
