defmodule StreamClosedCaptionerPhoenixWeb.DashboardControllerToggleTest do
  use StreamClosedCaptionerPhoenixWeb.ConnCase, async: true
  
  import StreamClosedCaptionerPhoenix.Factory
  
  describe "toggle_translation/2" do
    setup do
      user = insert(:user)
      # Update the pre-created stream_settings instead of inserting a new one
      {:ok, stream_settings} = StreamClosedCaptionerPhoenix.Settings.update_stream_settings(
        user.stream_settings, 
        %{translation_enabled: false}
      )
      
      %{user: user, stream_settings: stream_settings}
    end
    
    test "toggles translation_enabled to true when false", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      
      conn = post(conn, "/toggle-translation")
      
      assert redirected_to(conn) == "/dashboard"
      assert get_flash(conn, :info) == "Translation setting updated successfully."
      
      # Verify the setting was toggled
      {:ok, updated_settings} = StreamClosedCaptionerPhoenix.Settings.get_stream_settings_by_user_id(user.id)
      assert updated_settings.translation_enabled == true
    end
    
    test "toggles translation_enabled to false when true", %{conn: conn, user: user} do
      # Update the setting to true first
      {:ok, _} = StreamClosedCaptionerPhoenix.Settings.get_stream_settings_by_user_id(user.id)
        |> case do
          {:ok, settings} -> 
            StreamClosedCaptionerPhoenix.Settings.update_stream_settings(settings, %{translation_enabled: true})
        end
      
      conn = log_in_user(conn, user)
      
      conn = post(conn, "/toggle-translation")
      
      assert redirected_to(conn) == "/dashboard"
      assert get_flash(conn, :info) == "Translation setting updated successfully."
      
      # Verify the setting was toggled back to false
      {:ok, updated_settings} = StreamClosedCaptionerPhoenix.Settings.get_stream_settings_by_user_id(user.id)
      assert updated_settings.translation_enabled == false
    end
    
    test "requires authentication", %{conn: conn} do
      conn = post(conn, "/toggle-translation")
      
      assert redirected_to(conn) =~ "/users/log_in"
    end
  end
end