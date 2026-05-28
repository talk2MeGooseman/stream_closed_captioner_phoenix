defmodule StreamClosedCaptionerPhoenixWeb.LiveHelpers do
  alias StreamClosedCaptionerPhoenix.Accounts

  def live_modal(component, opts) do
    path = Keyword.fetch!(opts, :return_to)
    title = Keyword.fetch!(opts, :title)

    Phoenix.Component.live_component(%{
      module: StreamClosedCaptionerPhoenixWeb.ModalComponent,
      id: :modal,
      return_to: path,
      title: title,
      component: component,
      opts: opts
    })
  end

  def session_current_user(session) do
    session
    |> Map.get("user_token")
    |> Accounts.get_user_by_session_token()
  end
end
