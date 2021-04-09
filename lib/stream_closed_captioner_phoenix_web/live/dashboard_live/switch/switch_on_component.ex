defmodule StreamClosedCaptionerPhoenixWeb.DashboardLive.SwitchOnComponent do
  use StreamClosedCaptionerPhoenixWeb, :live_component

  def render(assigns) do
    ~L"""
    <label for="checked" class="mt-3 inline-flex items-center cursor-pointer">
      <span class="relative">
        <span class="block w-10 h-6 bg-gray-400 rounded-full shadow-inner"></span>
        <span class="absolute block w-4 h-4 mt-1 ml-1 rounded-full shadow inset-y-0 left-0 focus-within:shadow-outline transition-transform duration-300 ease-in-out bg-purple-600 transform translate-x-full">
          <input id="checked" type="checkbox" class="absolute opacity-0 w-0 h-0" />
        </span>
      </span>
      <span class="ml-3 text-sm">On</span>
    </label>
    """
  end
end
