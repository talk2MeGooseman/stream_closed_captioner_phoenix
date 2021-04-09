defmodule StreamClosedCaptionerPhoenixWeb.DashboardLive.TwitchEnabledIndicatorComponent do
  use StreamClosedCaptionerPhoenixWeb, :live_component

  def render(assigns) do
    ~L"""
    <div>
      <div class="flex-row items-center p-5 card">
        <div class="flex items-center justify-center w-10 h-10 text-green-700 bg-green-100 rounded">
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class="flex-none w-5 h-5">
            <path fill-rule="evenodd"
              d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
              clip-rule="evenodd" />
          </svg>
        </div>
        <div class="ml-3">
          <h2 class="mb-1 text-lg font-bold leading-none text-gray-900 truncate">Twitch Extension</h2>
          <p class="text-sm leading-none text-gray-600">Available and ready to start</p>
        </div>
        <div class="flex-grow text-right">
          <label for="unchecked" class="mt-3 inline-flex items-center cursor-pointer">
            <span class="relative">
              <span class="block w-10 h-6 bg-gray-400 rounded-full shadow-inner"></span>
              <span class="absolute block w-4 h-4 mt-1 ml-1 bg-white rounded-full shadow inset-y-0 left-0 focus-within:shadow-outline transition-transform duration-300 ease-in-out">
                <input id="unchecked" type="checkbox" class="absolute opacity-0 w-0 h-0" />
              </span>
            </span>
            <div class="ml-3 text-sm">Off</div>
          </label>

          <label for="checked" class="mt-3 inline-flex items-center cursor-pointer">
            <span class="relative">
              <span class="block w-10 h-6 bg-gray-400 rounded-full shadow-inner"></span>
              <span class="absolute block w-4 h-4 mt-1 ml-1 rounded-full shadow inset-y-0 left-0 focus-within:shadow-outline transition-transform duration-300 ease-in-out bg-purple-600 transform translate-x-full">
                <input id="checked" type="checkbox" class="absolute opacity-0 w-0 h-0" />
              </span>
            </span>
            <span class="ml-3 text-sm">On</span>
          </label>
        </div>
      </div>
    </div>
    """
  end
end
