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
    Logger.critical("Timer fire #{inspect(state)}")
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

    feed_content = Finch.build(:get, feed.url) |> Finch.request!(Pheeds.Finch)

    inserted =
      feed_content.body
      |> xpath(~x"//item"l,
        title: ~x"./title/text()"s,
        link: ~x"./link/text()"s,
        published_date: ~x"./pubDate/text()"s
      )
      |> Stream.map(&build_article/1)
      |> Stream.filter(&(&1 != nil))
      |> Stream.chunk_every(200)
      |> Enum.reduce(0, &(SourceFeeds.insert_articles!(&1) + &2))

    Logger.debug("Inserted #{inserted} new articles for feed #{feed.id}")

    SourceFeeds.end_updating!(feed)
  rescue
    e ->
      Logger.error("Error processing feed #{feed.id}: #{inspect(e)}")
      SourceFeeds.error_updating!(feed)
  end

  defp build_article(xml_map) do
    new_props = %{
      published_date: Article.parse_published_date!(xml_map[:published_date]),
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
