defmodule StreamClosedCaptionerPhoenixWeb.CaptionSettingsLive.Index do
  use StreamClosedCaptionerPhoenixWeb, :live_view

  import StreamClosedCaptionerPhoenixWeb.LiveHelpers

  alias StreamClosedCaptionerPhoenix.{Repo, Settings}

  @impl true
  def mount(_params, session, socket) do
    current_user =
      session_current_user(session)
      |> Repo.preload([:stream_settings, :translate_languages])

    language =
      if Enum.empty?(current_user.translate_languages) do
        %Settings.TranslateLanguage{}
      else
        Enum.at(current_user.translate_languages, 0)
      end

    socket =
      assign(socket, :current_user, current_user)
      |> assign(:changeset, Settings.change_stream_settings(current_user.stream_settings))
      |> assign(
        :language_changeset,
        Settings.change_translate_language(language)
      )
      |> assign(:translatable_language, Settings.translateable_language_list())
      |> assign(:live_socket_id, Map.get(session, "live_socket_id"))
      |> assign(:stream_settings, current_user.stream_settings)
      |> assign(:selected_language, language)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, _, _params) do
    socket
    |> assign(:page_title, "Captions settings")
  end

  @impl true
  def handle_event(
        "remove_blocklist_word",
        %{"word" => word} = _params,
        socket
      ) do
    current_user =
      socket.assigns.current_user
      |> Repo.preload(:stream_settings, force: true)

    new_blocklist = List.delete(current_user.stream_settings.blocklist, word)

    params = %{"blocklist" => new_blocklist}

    case Settings.update_stream_settings(current_user.stream_settings, params) do
      {:ok, stream_settings} ->
        {:noreply,
         socket
         |> assign(:stream_settings, stream_settings)
         |> put_flash(:info, "Blocklist word removed successfully.")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  @impl true
  def handle_event(
        "add",
        %{"stream_settings" => %{"blocklist_word" => blocklist_word}},
        socket
      )
      when byte_size(blocklist_word) == 0 do
    {:noreply, assign(socket, :changeset, socket.assigns.changeset)}
  end

  def handle_event(
        "add",
        %{"stream_settings" => %{"blocklist_word" => blocklist_word}},
        socket
      ) do
    blocklist = socket.assigns.stream_settings.blocklist
    new_word = String.trim(blocklist_word)

    params = %{"blocklist" => [new_word | blocklist]}

    case Settings.update_stream_settings(socket.assigns.stream_settings, params) do
      {:ok, stream_settings} ->
        {:noreply,
         socket
         |> assign(:stream_settings, stream_settings)
         |> put_flash(:info, "Blocklist word added successfully.")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  def handle_event(
        "add",
        %{"translate_language" => new_selected_language},
        %{assigns: %{selected_language: %{id: nil}}} = socket
      ) do
    case Settings.create_translate_language(
           socket.assigns.current_user,
           new_selected_language
         ) do
      {:ok, selected_language} ->
        {:noreply,
         socket
         |> assign(:selected_language, selected_language)
         |> assign(
           :language_changeset,
           Settings.change_translate_language(selected_language)
         )
         |> put_flash(:info, "Updated translation language.")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  def handle_event(
        "add",
        %{"translate_language" => new_selected_language},
        %{assigns: %{selected_language: %{id: id}}} = socket
      ) do
    case Settings.update_translate_language(
           socket.assigns.selected_language,
           new_selected_language
         ) do
      {:ok, selected_language} ->
        {:noreply,
         socket
         |> assign(:selected_language, selected_language)
         |> assign(
           :language_changeset,
           Settings.change_translate_language(selected_language)
         )
         |> put_flash(:info, "Updated translation language.")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end
end
