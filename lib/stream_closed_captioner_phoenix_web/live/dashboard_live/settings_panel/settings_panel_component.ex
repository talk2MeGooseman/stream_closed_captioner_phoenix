defmodule StreamClosedCaptionerPhoenixWeb.DashboardLive.SettingsPanelComponent do
  use StreamClosedCaptionerPhoenixWeb, :live_component

  def render(assigns) do
    settings_block_list = [
      :caption_delay,
      :cc_box_size,
      :language,
      :filter_profanity,
      :hide_text_on_load,
      :text_uppercase,
      :switch_settings_position
    ]

    ~L"""
    <div class="card">
    <div class="px-4 py-3 border-0 card-header">
      <h4 class="font-medium text-gray-800">Current Settings</h4>
    </div>
    <div class="px-4 mb-1 -mt-2 divide-y divide-gray-200 card-body">
      <%= for { setting_name, value } <- Map.take(@settings, settings_block_list) |> Map.to_list do %>
        <div class="flex items-center justify-between py-3 text-sm">
          <div class="flex items-center space-x-2 text-gray-700">
            <span><%= humanized_name(setting_name) %></span>
          </div>
          <%= cond do %>
          <% value == :true -> %>
            <span class="badge bg-green-700 text-white">Enabled</span>
          <% value == :false -> %>
            <span class="badge bg-red-700 text-white">Disabled</span>
          <% true -> %>
            <%= value %>
          <% end %>
        </div>
      <% end %>
    </div>
    <%= live_patch "Click Here to Update Settings", to: Routes.dashboard_index_path(@socket, :settings), class: "px-4 py-3 text-sm font-medium text-purple-700 hover:text-purple-900 card-footer" %></span>
    </div>
    """
  end

  defp humanized_name(name) do
    %{
      caption_delay: "Captions Delay",
      cc_box_size: "Display Captions in Box Size",
      language: "Language",
      filter_profanity: "Censor Profanity",
      hide_text_on_load: "Hide Captions by Default",
      text_uppercase: "Uppercase Text By Default",
      switch_settings_position: "Display Settings on Left Side"
    }
    |> Map.get(name)
  end
end
