defmodule StreamClosedCaptionerPhoenixWeb.DashboardLive.TwitchDisabledIndicatorComponent do
  use StreamClosedCaptionerPhoenixWeb, :live_component

  def render(assigns) do
    ~L"""
    <div>
      <div class="flex-row items-center p-5 card" x-data="tooltip()" x-spread="tooltip" title="In order to use Twitch you must connect your Twitch account to your Stream CC account." x-position="bottom">
        <div class="flex items-center justify-center w-10 h-10 text-green-700 bg-green-100 rounded">
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class="flex-none w-5 h-5">
            <path fill-rule="evenodd"
              d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z"
              clip-rule="evenodd" />
          </svg>
        </div>
        <div class="ml-3">
          <h2 class="mb-1 text-lg font-bold leading-none text-gray-900 truncate">Twitch Extension</h2>
          <p class="text-sm leading-none text-gray-600">Not Unavailable</p>
        </div>
        <div class="flex-grow text-right">
        </div>
      </div>
    </div>
    """
  end
end
