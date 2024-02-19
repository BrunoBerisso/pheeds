defmodule Pheeds.SourceFeedsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Pheeds.SourceFeeds` context.
  """

  @doc """
  Generate a feed.
  """
  def feed_fixture(attrs \\ %{}) do
    {:ok, feed} =
      attrs
      |> Enum.into(%{
        last_update: ~N[2024-02-18 16:12:00],
        status: 42,
        title: "some title",
        url: "some url"
      })
      |> Pheeds.SourceFeeds.create_feed()

    feed
  end
end
