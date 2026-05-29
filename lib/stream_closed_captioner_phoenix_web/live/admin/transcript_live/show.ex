defmodule StreamClosedCaptionerPhoenixWeb.Admin.TranscriptLive.Show do
  use StreamClosedCaptionerPhoenixWeb, :admin_live_view
  alias StreamClosedCaptionerPhoenix.Admin

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id} = params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params, id)}
  end

  defp apply_action(socket, :show, _params, id) do
    transcript = Admin.get_transcript!(id)

    socket
    |> assign(:page_title, "Transcript — #{transcript.name}")
    |> assign(:transcript, transcript)
    |> assign(:record, nil)
  end

  defp apply_action(socket, :edit, _params, id) do
    transcript = Admin.get_transcript!(id)

    socket
    |> assign(:page_title, "Edit Transcript — #{transcript.name}")
    |> assign(:transcript, transcript)
    |> assign(:record, transcript)
  end

  @impl true
  def handle_info({:saved, updated}, socket) do
    {:noreply,
     socket
     |> put_flash(:info, "Saved.")
     |> assign(:transcript, Admin.get_transcript!(updated.id))}
  end

  @impl true
  def handle_event("delete_message", %{"id" => id}, socket) do
    {:ok, _} = Admin.delete_message(Admin.get_message!(id))

    {:noreply,
     socket
     |> put_flash(:info, "Message deleted.")
     |> assign(:transcript, Admin.get_transcript!(socket.assigns.transcript.id))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.admin_page_header title={"Transcript: #{@transcript.name}"}>
      <:actions>
        <.admin_button patch={~p"/admin/transcripts/#{@transcript.id}/show/edit"}>
          Edit Transcript
        </.admin_button>
        <.admin_button navigate={~p"/admin/transcripts"}>← All Transcripts</.admin_button>
      </:actions>
    </.admin_page_header>

    <div class="bg-white rounded-lg border border-gray-200 shadow-sm mb-6">
      <div class="px-5 py-4 border-b border-gray-100 flex items-center justify-between">
        <h2 class="text-sm font-semibold text-gray-900">Transcript Details</h2>
        <.edit_button patch={~p"/admin/transcripts/#{@transcript.id}/show/edit"} />
      </div>
      <div class="px-5 py-4 grid grid-cols-1 sm:grid-cols-2 gap-x-8 gap-y-3 text-sm">
        <div>
          <span class="text-gray-500 font-medium">ID</span>
          <span class="ml-2 text-gray-900"><%= @transcript.id %></span>
        </div>
        <div>
          <span class="text-gray-500 font-medium">Name</span>
          <span class="ml-2 text-gray-900"><%= @transcript.name || "—" %></span>
        </div>
        <div>
          <span class="text-gray-500 font-medium">Session</span>
          <span class="ml-2 text-gray-900 font-mono text-xs"><%= @transcript.session || "—" %></span>
        </div>
        <div>
          <span class="text-gray-500 font-medium">User</span>
          <span class="ml-2"><.user_link user={@transcript.user} /></span>
        </div>
        <div>
          <span class="text-gray-500 font-medium">Created</span>
          <span class="ml-2 text-gray-900"><%= format_dt(@transcript.created_at) %></span>
        </div>
      </div>
    </div>

    <div class="bg-white rounded-lg border border-gray-200 shadow-sm mb-6">
      <div class="px-5 py-4 border-b border-gray-100 flex items-center justify-between">
        <div class="flex items-center gap-2">
          <h2 class="text-sm font-semibold text-gray-900">Messages</h2>
          <span class="text-xs bg-gray-100 text-gray-600 rounded-full px-2 py-0.5">
            <%= length(@transcript.messages) %>
          </span>
        </div>
        <.admin_button navigate={~p"/admin/messages/new"}>+ New Message</.admin_button>
      </div>
      <div class="overflow-x-auto">
        <.admin_table
          id={"transcript-messages-#{@transcript.id}"}
          rows={@transcript.messages}
          row_id={fn m -> "message-#{m.id}" end}
        >
          <:col :let={m} label="ID"><%= m.id %></:col>
          <:col :let={m} label="Text"><%= m.text %></:col>
          <:col :let={m} label="Created At"><%= format_dt(m.created_at) %></:col>
          <:col :let={m} label="Actions">
            <div class="flex items-center gap-1">
              <.edit_button patch={~p"/admin/messages/#{m.id}/edit"} />
              <.danger_button
                phx-click="delete_message"
                phx-value-id={m.id}
                data-confirm="Are you sure you want to delete this message?"
              >
                Delete
              </.danger_button>
            </div>
          </:col>
        </.admin_table>
      </div>
    </div>

    <%= if @live_action == :edit do %>
      <.admin_modal
        id="transcript-show-form-modal"
        show={true}
        on_cancel={JS.patch(~p"/admin/transcripts/#{@transcript.id}")}
      >
        <.live_component
          module={StreamClosedCaptionerPhoenixWeb.Admin.TranscriptLive.FormComponent}
          id={"transcript-show-edit-#{@transcript.id}"}
          action={:edit}
          record={@record}
          patch={~p"/admin/transcripts/#{@transcript.id}"}
        />
      </.admin_modal>
    <% end %>
    """
  end

  defp format_dt(nil), do: "—"
  defp format_dt(dt), do: NaiveDateTime.to_string(dt) |> String.slice(0, 16)
end
