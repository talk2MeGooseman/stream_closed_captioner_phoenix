defmodule StreamClosedCaptionerPhoenixWeb.LiveHelpers do
  import Phoenix.LiveView.Helpers

  alias StreamClosedCaptionerPhoenix.Accounts

  @doc """
  Renders a component inside the `StreamClosedCaptionerPhoenixWeb.ModalComponent` component.

  The rendered modal receives a `:return_to` option to properly update
  the URL when the modal is closed.

  ## Examples

      <%= live_modal @socket, StreamClosedCaptionerPhoenixWeb.CaptionSettingsLive.FormComponent,
        id: @stream_settings.id || :new,
        action: @live_action,
        stream_settings: @stream_settings,
        return_to: Routes.stream_settings_index_path(@socket, :index) %>
  """
  def live_modal(component, opts) do
    path = Keyword.fetch!(opts, :return_to)
    title = Keyword.fetch!(opts, :title)
    modal_opts = [id: :modal, return_to: path, title: title, component: component, opts: opts]
    live_component(StreamClosedCaptionerPhoenixWeb.ModalComponent, modal_opts)
  end

  def session_current_user(session) do
    session
    |> Map.get("user_token")
    |> Accounts.get_user_by_session_token()
  end
end
