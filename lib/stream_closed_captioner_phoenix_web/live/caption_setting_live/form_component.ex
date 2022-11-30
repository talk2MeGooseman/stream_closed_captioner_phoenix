defmodule StreamClosedCaptionerPhoenixWeb.CaptionSettingLive.FormComponent do
  use StreamClosedCaptionerPhoenixWeb, :live_component

  alias StreamClosedCaptionerPhoenix.Accounts

  @impl true
  def update(%{caption_setting: caption_setting} = assigns, socket) do
    changeset = Accounts.change_caption_setting(caption_setting)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("validate", %{"caption_setting" => caption_setting_params}, socket) do
    changeset =
      socket.assigns.caption_setting
      |> Accounts.change_caption_setting(caption_setting_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"caption_setting" => caption_setting_params}, socket) do
    save_caption_setting(socket, socket.assigns.action, caption_setting_params)
  end

  defp save_caption_setting(socket, :edit, caption_setting_params) do
    case Accounts.update_caption_setting(socket.assigns.caption_setting, caption_setting_params) do
      {:ok, _caption_setting} ->
        {:noreply,
         socket
         |> put_flash(:info, "Caption setting updated successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_caption_setting(socket, :new, caption_setting_params) do
    case Accounts.create_caption_setting(caption_setting_params) do
      {:ok, _caption_setting} ->
        {:noreply,
         socket
         |> put_flash(:info, "Caption setting created successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
