defmodule StreamClosedCaptionerPhoenixWeb.DashboardLive.TwitchEnabledIndicatorComponent do
  use StreamClosedCaptionerPhoenixWeb, :live_component

  def render(assigns) do
    ~L"""
    <div phx-update="ignore">
      <div class="p-5 card" data-controller="twitch">
        <div class="flex flex-row items-center">
          <div data-twitch-target="errorMarker"
            class="hidden flex items-center justify-center w-10 h-10 text-red-700 bg-red-100 rounded">
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class="flex-none w-5 h-5">
              <path fill-rule="evenodd"
                d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z"
                clip-rule="evenodd" />
            </svg>
          </div>
          <div class="ml-3">
            <h2 class="mb-1 text-lg font-bold leading-none text-gray-900 truncate">Twitch Extension Captions</h2>
            <p class="text-sm leading-none text-gray-600">Available and ready to turn on</p>
          </div>
          <div class="flex-grow text-right">
            <div data-action="mousedown->twitch#toggleOn">
              <div class="hidden" data-twitch-target="offSwitch">
                <%= live_component @socket, StreamClosedCaptionerPhoenixWeb.DashboardLive.SwitchOffComponent %>
              </div>
              <div data-twitch-target="onSwitch">
                <%= live_component @socket, StreamClosedCaptionerPhoenixWeb.DashboardLive.SwitchOnComponent %>
              </div>
            </div>
          </div>
        </div>
        <div data-twitch-target="errorMessage" class="alert mt-2 hidden text-red-700 bg-red-100" role="alert"></div>
      </div>
    </div>
    """
  end
end
