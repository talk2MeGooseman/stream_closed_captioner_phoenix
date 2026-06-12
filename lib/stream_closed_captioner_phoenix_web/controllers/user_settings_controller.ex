defmodule StreamClosedCaptionerPhoenixWeb.UserSettingsController do
  use StreamClosedCaptionerPhoenixWeb, :controller

  alias StreamClosedCaptionerPhoenix.{Accounts, AccountsOauth, AuditLog}
  alias StreamClosedCaptionerPhoenixWeb.{Layouts, UserAuth}

  plug :assign_email_and_password_changesets

  def edit(conn, _params) do
    conn
    |> put_scc_layout()
    |> render("edit.html")
  end

  def update(conn, %{"action" => "update_email"} = params) do
    %{"current_password" => password, "user" => user_params} = params
    user = conn.assigns.current_user

    case Accounts.apply_user_email(user, password, user_params) do
      {:ok, applied_user} ->
        AuditLog.info("user_settings.email_update_requested", %{user_id: applied_user.id})

        Accounts.deliver_update_email_instructions(
          applied_user,
          user.email,
          &url(~p"/users/settings/confirm_email/#{&1}")
        )

        conn
        |> put_flash(
          :info,
          "A link to confirm your email change has been sent to the new address."
        )
        |> redirect(to: ~p"/users/settings")

      {:error, changeset} ->
        AuditLog.warn("user_settings.email_update_request_failed", %{user_id: user.id})

        conn
        |> put_scc_layout()
        |> render("edit.html", email_changeset: changeset)
    end
  end

  def update(conn, %{"action" => "update_password"} = params) do
    %{"current_password" => password, "user" => user_params} = params
    user = conn.assigns.current_user

    case Accounts.update_user_password(user, password, user_params) do
      {:ok, user} ->
        AuditLog.info("user_settings.password_changed", %{user_id: user.id})

        conn
        |> put_flash(:info, "Password updated successfully.")
        |> put_session(:user_return_to, ~p"/users/settings")
        |> UserAuth.log_in_user(user)

      {:error, changeset} ->
        AuditLog.warn("user_settings.password_change_failed", %{user_id: user.id})

        conn
        |> put_scc_layout()
        |> render("edit.html", password_changeset: changeset)
    end
  end

  def update(conn, %{"action" => "remove_provider"}) do
    user = conn.assigns.current_user

    case Accounts.remove_user_provider(user) do
      {:ok, _user} ->
        AuditLog.info("user_settings.provider_unlinked", %{user_id: user.id, provider: "twitch"})

        conn
        |> put_flash(:info, "Twitch connection successfully removed.")
        |> redirect(to: ~p"/users/settings")

      {:error, changeset} ->
        AuditLog.warn("user_settings.provider_unlink_failed", %{
          user_id: user.id,
          provider: "twitch"
        })

        conn
        |> put_scc_layout()
        |> render("edit.html", password_changeset: changeset)
    end
  end

  def confirm_email(conn, %{"token" => token}) do
    case Accounts.update_user_email(conn.assigns.current_user, token) do
      :ok ->
        conn
        |> put_flash(:info, "Email changed successfully.")
        |> redirect(to: ~p"/users/settings")

      :error ->
        conn
        |> put_flash(:error, "Email change link is invalid or it has expired.")
        |> redirect(to: ~p"/users/settings")
    end
  end

  # Render the account settings page in the Stream CC design language. Bare-tuple
  # `put_root_layout` so it replaces the `:logged_in` pipeline's root layout (a
  # `[html: ...]` form would be shadowed by the pipeline's catch-all). Mirrors
  # DashboardController.index. No `:scc_active` — "settings" isn't a nav item.
  defp put_scc_layout(conn) do
    conn
    |> put_root_layout({Layouts, :scc_root})
    |> put_layout(html: {Layouts, :scc})
    |> assign(:page_title, "Account Settings")
  end

  defp assign_email_and_password_changesets(conn, _opts) do
    user = conn.assigns.current_user

    conn
    |> assign(:email_changeset, Accounts.change_user_email(user))
    |> assign(:password_changeset, Accounts.change_user_password(user))
    |> assign(:provider_changeset, AccountsOauth.change_user_provider(user))
    |> assign(:user, user)
  end
end
