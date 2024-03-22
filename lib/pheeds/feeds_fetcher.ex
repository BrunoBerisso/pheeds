defmodule Pheeds.FeedsFetcher do
  use GenServer, restart: :transient
  require Logger
  import SweetXml

  alias Pheeds.SourceFeeds
  alias SourceFeeds.{Feed, Article}

  @fetch_time 3_000

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(state) do
    Logger.info("Init Feed Fetcher: #{inspect(state)}")
    schedule_timer()
    {:ok, state}
  end

  @impl true
  def handle_info(:fetch_feeds, state) do
    Logger.debug("Timer fire #{inspect(state)}")
    SourceFeeds.list_feeds() |> Enum.each(&process_feed/1)
    schedule_timer()
    {:noreply, state}
  end

  defp schedule_timer do
    # If this process die the timer will be automatically clean up
    Process.send_after(self(), :fetch_feeds, @fetch_time)
  end

  defp process_feed(feed) do
    if Feed.status(feed) == :error do
      Logger.warning("Retring errored feed #{feed.id}")
    end

    SourceFeeds.start_updating!(feed)

    feed_uri = URI.parse(feed.url)
    base_url = feed_uri.scheme <> "://" <> feed_uri.host
    feed_content = Finch.build(:get, feed.url) |> Finch.request!(Pheeds.Finch)

    inserted =
      feed_content.body
      |> build_xpath(feed)
      |> Stream.map(&build_article(&1, base_url))
      |> Stream.filter(&(&1 != nil))
      |> Stream.chunk_every(200)
      |> Enum.reduce(0, &(SourceFeeds.insert_articles!(&1) + &2))

    Logger.debug("Inserted #{inserted} new articles for feed #{feed.id}")

    SourceFeeds.end_updating!(feed, inserted)
  rescue
    error ->
      error_desc = inspect(error)
      Logger.error("Error processing feed #{feed.id}: #{error_desc}")
      SourceFeeds.error_updating!(feed, error_desc)
  end

  defp build_xpath(feed_body, feed) do
    # FIXME: There are tree types of content: RSS, Atom and HTML. The first two are automatically suported by
    # the default values. HTML require that the user specify the xpath expressions to grab the right fields.
    # This should be enforced here
    is_rss = length(xpath(feed_body, ~x"/rss"l)) > 0

    items_expr = feed.items_xpath || if is_rss, do: "//item", else: "//entry"
    title_expr = feed.title_xpath || if is_rss, do: "./title/text()", else: "./title/text()"
    link_expr = feed.link_xpath || if is_rss, do: "./link/text()", else: "./link/@href"
    date_expr = feed.date_xpath || if is_rss, do: "./pubDate/text()", else: "./updated/text()"

    xpath(feed_body, sigil_x(items_expr, "l"),
      title: sigil_x(title_expr, "s"),
      link: sigil_x(link_expr, "s"),
      published_date: sigil_x(date_expr, "s")
    )
  end

  defp build_article(xml_map, base_url) do
    link_uri = URI.parse(xml_map[:link])

    new_props = %{
      published_date: Article.parse_published_date!(xml_map[:published_date]),
      link:
        if(link_uri.scheme,
          do: URI.to_string(link_uri),
          else: base_url <> URI.to_string(link_uri)
        ),
      # FIXME: setting these here is not cool... but it's the shortest way now. It would be better to set these
      # two with a default value in the DB but I don't want to mess around with the schema right now
      inserted_at: DateTime.utc_now(:second),
      updated_at: DateTime.utc_now(:second)
    }

    props = Map.merge(xml_map, new_props)

    if Article.changeset(%Article{}, props).valid? do
      props
    else
      nil
    end
  end
end
