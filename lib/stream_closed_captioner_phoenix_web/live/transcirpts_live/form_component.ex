defmodule StreamClosedCaptionerPhoenixWeb.TranscirptsLive.FormComponent do
  use StreamClosedCaptionerPhoenixWeb, :live_component

  alias StreamClosedCaptionerPhoenix.Captions

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage transcirpts records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="transcirpts-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >

        <:actions>
          <.button phx-disable-with="Saving...">Save Transcirpts</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{transcirpts: transcirpts} = assigns, socket) do
    changeset = Captions.change_transcirpts(transcirpts)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"transcirpts" => transcirpts_params}, socket) do
    changeset =
      socket.assigns.transcirpts
      |> Captions.change_transcirpts(transcirpts_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"transcirpts" => transcirpts_params}, socket) do
    save_transcirpts(socket, socket.assigns.action, transcirpts_params)
  end

  defp save_transcirpts(socket, :edit, transcirpts_params) do
    case Captions.update_transcirpts(socket.assigns.transcirpts, transcirpts_params) do
      {:ok, transcirpts} ->
        notify_parent({:saved, transcirpts})

        {:noreply,
         socket
         |> put_flash(:info, "Transcirpts updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_transcirpts(socket, :new, transcirpts_params) do
    case Captions.create_transcirpts(transcirpts_params) do
      {:ok, transcirpts} ->
        notify_parent({:saved, transcirpts})

        {:noreply,
         socket
         |> put_flash(:info, "Transcirpts created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
