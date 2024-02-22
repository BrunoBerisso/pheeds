defmodule PheedsWeb.ArticlesLive.Index do
  use PheedsWeb, :live_view

  alias Pheeds.SourceFeeds

  @pagination_limit 50
  @stream_limit 150

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

  def mount(_params, _session, socket) do
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

  def handle_event("next-page", _, socket) do
    {:noreply, paginate_article(socket, :next)}
  end

  def handle_event("previous-page", params, socket) do
    direction = if params["_overran"], do: :reset, else: :previous
    {:noreply, paginate_article(socket, direction)}
  end
end
