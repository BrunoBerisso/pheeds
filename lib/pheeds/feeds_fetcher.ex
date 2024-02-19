defmodule Pheeds.FeedsFetcher do
  use GenServer, restart: :transient
  require Logger

  @fetch_time 1_000

  def init(%{} = state) do
    schedule_timer()
    {:ok, state}
  end

  def handle_info(:fetch_feeds, state) do

  end

  defp schedule_timer do
    Process.send_after(self(), :fetch_feeds, @fetch_time)
  end

end
