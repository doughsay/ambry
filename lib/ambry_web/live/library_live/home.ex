defmodule AmbryWeb.LibraryLive.Home do
  @moduledoc """
  LiveView for the library page.
  """

  use AmbryWeb, :p_live_view

  alias Ambry.PubSub
  alias AmbryWeb.Components.PlayButton
  alias AmbryWeb.LibraryLive.Home.{RecentBooks, RecentMedia}

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    socket =
      if connected?(socket) do
        browser_id = socket |> get_connect_params() |> Map.fetch!("browser_id")

        assign(socket, :browser_id, browser_id)
      else
        socket
      end

    {:ok, assign(socket, :page_title, "Library")}
  end

  @impl Phoenix.LiveView
  def handle_info({:playback_started, media_id}, socket) do
    PlayButton.play(media_id)
    {:noreply, socket}
  end

  def handle_info({:playback_paused, media_id}, socket) do
    PlayButton.pause(media_id)
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("play-pause", %{"media_id" => media_id}, socket) do
    user = socket.assigns.current_user
    browser_id = socket.assigns.browser_id
    playing = Ambry.PlayerStateRegistry.is_playing?(user.id, browser_id, media_id)

    if playing do
      PubSub.pub(:pause, user.id, browser_id)
    else
      PubSub.pub(:load_and_play_media, user.id, browser_id, media_id)
    end

    {:noreply, socket}
  end
end