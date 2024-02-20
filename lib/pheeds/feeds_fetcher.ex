defmodule Pheeds.FeedsFetcher do
  use GenServer, restart: :transient
  require Logger
  import SweetXml

  alias Pheeds.SourceFeeds
  alias SourceFeeds.Feed

  @fetch_time 3_000

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def init(state) do
    Logger.critical("Init workder #{inspect(state)}")
    schedule_timer()
    {:ok, state}
  end

  def handle_info(:fetch_feeds, state) do
    Logger.critical("Timer fire #{inspect(state)}")
    # List feeds with status == pending
    SourceFeeds.list_feeds() |> Enum.each(&(process_feed/1))
    schedule_timer()
    {:noreply, state}
  end

  defp schedule_timer do
    # If this process die the timer will be automatically clean up
    Process.send_after(self(), :fetch_feeds, @fetch_time)
  end

  def process_feed(feed) do
    if Feed.status(feed) == :error do
      Logger.warning("Retring errored feed #{feed.id}")
    end

    SourceFeeds.start_updating!(feed)

    feed_content = Finch.build(:get, feed.url) |> Finch.request!(Pheeds.Finch)
    items = feed_content.body |> xpath(~x"//item"l, title: ~x"./title/text()", link: ~x"./link/text()")
    Logger.debug("Got #{length(items)} items for feed #{feed.title}")

    SourceFeeds.end_updating!(feed)
  rescue
    e ->
      Logger.error("Error processing feed #{feed.id}: #{inspect(e)}")
      SourceFeeds.eror_updating!(feed)
  end

end
