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
          <h2 class="mb-1 text-lg font-bold leading-none text-gray-900 truncate">Twitch Extension Captions</h2>
          <p class="text-sm leading-none text-gray-600">Please connect your Twitch account to enable this feature.</p>
        </div>
        <div class="flex-grow text-right">
         <a href="/auth/twitch" class="w-full py-3 btn btn-icon btn-primary">
          <svg version="1.1" id="Layer_1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"
            x="0px" y="0px" viewBox="0 0 2400 2800" style="enable-background:new 0 0 2400 2800;" xml:space="preserve">
            <style type="text/css">
              .st0 {
                fill: #FFFFFF;
              }

              .st1 {
                fill: #9146FF;
              }
            </style>
            <title>Twitch Glitch</title>
            <g>
              <polygon class="st0"
                points="2200,1300 1800,1700 1400,1700 1050,2050 1050,1700 600,1700 600,200 2200,200 	" />
              <g>
                <g id="Layer_1-2">
                  <path class="st1" d="M500,0L0,500v1800h600v500l500-500h400l900-900V0H500z M2200,1300l-400,400h-400l-350,350v-350H600V200h1600
          V1300z" />
                  <rect x="1700" y="550" class="st1" width="200" height="600" />
                  <rect x="1150" y="550" class="st1" width="200" height="600" />
                </g>
              </g>
            </g>
            </svg>
          </a>
        </div>
      </div>
    </div>
    """
  end
end
