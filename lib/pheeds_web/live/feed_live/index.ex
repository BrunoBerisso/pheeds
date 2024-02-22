defmodule PheedsWeb.FeedLive.Index do
  alias Phoenix.PubSub
  use PheedsWeb, :live_view

  alias Pheeds.SourceFeeds
  alias Pheeds.SourceFeeds.Feed

  @impl true
  def mount(_params, _session, socket) do
    PubSub.subscribe(Pheeds.PubSub, "feed_fetcher")
    {:ok, stream(socket, :feeds, SourceFeeds.list_feeds())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Feed")
    |> assign(:feed, SourceFeeds.get_feed!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Feed")
    |> assign(:feed, %Feed{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Feeds")
    |> assign(:feed, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    feed = SourceFeeds.get_feed!(id)
    {:ok, _} = SourceFeeds.delete_feed(feed)

    {:noreply, stream_delete(socket, :feeds, feed)}
  end

  @impl true
  def handle_info({PheedsWeb.FeedLive.FormComponent, {:saved, feed}}, socket) do
    {:noreply, stream_insert(socket, :feeds, feed)}
  end

  def handle_info({:feed_fetcher, {_, [{:feed, feed} | _]}}, socket) do
    {:noreply, socket |> stream_insert(:feeds, feed)}
  end
end
