defmodule StreamClosedCaptionerPhoenixWeb.ModalComponent do
  use StreamClosedCaptionerPhoenixWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div
      class="fixed top-0 left-0 z-50 w-full h-full outline-none"
      id={@id}
      role="dialog"
      style="display: block"
      phx-capture-click="close"
      phx-window-keydown="close"
      phx-key="escape"
      phx-target="#{@id}"
      phx-page-loading
    >
      <div class="relative w-auto pointer-events-none max-w-lg my-8 mx-auto px-4 sm:px-0 shadow-lg">
        <div class="relative flex flex-col w-full pointer-events-auto bg-white border border-gray-300 rounded-lg">
          <div class="flex items-start justify-between p-4 border-b border-gray-300 rounded-t">
            <h5 class="mb-0 text-lg leading-normal"><%= @title %></h5>
            <.link navigate={@return_to} class="text-gray-500 hover:text-gray-600 font-bold text-lg">
              <%= raw("&times;") %>
            </.link>
          </div>
          <div class="relative flex-auto p-4">
            <.live_component module={@component} opts={@opts} />
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("close", _, socket) do
    {:noreply, push_patch(socket, to: socket.assigns.return_to)}
  end
end
