defmodule PheedsWeb.ArticlesLive.Index do
  alias Phoenix.PubSub
  use PheedsWeb, :live_view
  require Logger

  alias Pheeds.SourceFeeds

  @pagination_limit 50
  @stream_limit 100

  @impl true
  def render(assigns) do
    ~H"""
    <.header class="pb-10">
      The Pheeds
      <:actions>
        <.link patch={~p"/feeds"}>
          <.button>Manage Feeds</.button>
        </.link>
      </:actions>
    </.header>
    <ul
      id="articles"
      phx-update="stream"
      phx-viewport-top={@page > 1 && "previous-page"}
      phx-viewport-bottom={@has_more_articles? && "next-page"}
      phx-page-loading
      class={[
        if(@page == 1, do: "pt-0", else: "pt-[calc(100vh)]"),
        if(!@has_more_articles?, do: "pb-0", else: "pb-[calc(100vh)]"),
        "divide-y",
        "divide-gray-200",
        "dark:divide-gray-700"
      ]}
    >
      <li :for={{id, article} <- @streams.articles} id={id} class="py-2">
        <div class="flex justify-between min-w-0">
          <p class="text-sm font-medium text-gray-900 truncate">
            <%= article.title %>
          </p>
          <p class="text-sm text-gray-500 truncate dark:text-gray-400">
            <%= article.published_date %>
          </p>
        </div>
        <div class="inline-flex items-center text-base font-semibold text-gray-900 dark:text-white">
          <a
            href={"#{article.link}"}
            class="font-medium text-blue-600 underline dark:text-blue-500 hover:no-underline"
          >
            <%= article.link %>
          </a>
        </div>
      </li>
    </ul>
    <div :if={!@has_more_articles?} class="mt-5 text-[50px] text-center">
      🎉 You made it to the beginning of time 🎉
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    # This view will be automatically unsubscribed when the view process terminates
    PubSub.subscribe(Pheeds.PubSub, "feed_fetcher")
    {:ok, paginate_article(socket, :reset)}
  end

  defp paginate_article(socket, :reset) do
    first_page = 1
    articles = SourceFeeds.list_articles_paginated(first_page, @pagination_limit)

    socket
    |> assign(:has_more_articles?, true)
    |> assign(:page, first_page)
    |> stream(:articles, articles, reset: true)
  end

  defp paginate_article(socket, :next) do
    next_page = socket.assigns.page + 1
    articles = SourceFeeds.list_articles_paginated(next_page, @pagination_limit)

    socket
    |> assign(:has_more_articles?, articles != [])
    |> assign(:page, next_page)
    |> stream(:articles, articles, at: -1, limit: @stream_limit * -1)
  end

  defp paginate_article(socket, :previous) do
    prev_page = socket.assigns.page - 1

    if prev_page == 0 do
      socket
    else
      articles = SourceFeeds.list_articles_paginated(prev_page, @pagination_limit)

      socket
      |> assign(:has_more_articles?, articles != [])
      |> assign(:page, prev_page)
      |> stream(:articles, Enum.reverse(articles), at: 0, limit: @stream_limit)
    end
  end

  @impl true
  def handle_event("next-page", _, socket) do
    {:noreply, paginate_article(socket, :next)}
  end

  def handle_event("previous-page", params, socket) do
    direction = if params["_overran"], do: :reset, else: :previous
    {:noreply, paginate_article(socket, direction)}
  end

  @impl true
  def handle_info(:clear_flash, socket) do
    {:noreply, clear_flash(socket)}
  end

  def handle_info(msg, socket) do
    socket =
      case msg do
        {:done, [_, {:title, feed_title}, {:added, cnt}]} when cnt > 0 ->
          Process.send_after(self(), :clear_flash, 3000)
          put_flash(socket, :info, "Added #{cnt} articles from #{feed_title}")

        {:error, [_, {:title, feed_title}, {:error, msg}]} ->
          Process.send_after(self(), :clear_flash, 3000)
          put_flash(socket, :error, "Fetching failed for feed #{feed_title}: #{msg}")

        _ ->
          socket
      end

    Logger.debug("articles_live received #{inspect(msg)} - #{inspect(socket)}")
    {:noreply, socket}
  end
end
