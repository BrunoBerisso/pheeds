defmodule Pheeds.SourceFeedsTest do
  use Pheeds.DataCase

  alias Pheeds.SourceFeeds

  describe "feeds" do
    alias Pheeds.SourceFeeds.Feed

    import Pheeds.SourceFeedsFixtures

    @invalid_attrs %{status: nil, title: nil, url: nil, last_update: nil}

    test "list_feeds/0 returns all feeds" do
      feed = feed_fixture()
      assert SourceFeeds.list_feeds() == [feed]
    end

    test "get_feed!/1 returns the feed with given id" do
      feed = feed_fixture()
      assert SourceFeeds.get_feed!(feed.id) == feed
    end

    test "create_feed/1 with valid data creates a feed" do
      valid_attrs = %{status: 42, title: "some title", url: "some url", last_update: ~N[2024-02-18 16:12:00]}

      assert {:ok, %Feed{} = feed} = SourceFeeds.create_feed(valid_attrs)
      assert feed.status == 42
      assert feed.title == "some title"
      assert feed.url == "some url"
      assert feed.last_update == ~N[2024-02-18 16:12:00]
    end

    test "create_feed/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = SourceFeeds.create_feed(@invalid_attrs)
    end

    test "update_feed/2 with valid data updates the feed" do
      feed = feed_fixture()
      update_attrs = %{status: 43, title: "some updated title", url: "some updated url", last_update: ~N[2024-02-19 16:12:00]}

      assert {:ok, %Feed{} = feed} = SourceFeeds.update_feed(feed, update_attrs)
      assert feed.status == 43
      assert feed.title == "some updated title"
      assert feed.url == "some updated url"
      assert feed.last_update == ~N[2024-02-19 16:12:00]
    end

    test "update_feed/2 with invalid data returns error changeset" do
      feed = feed_fixture()
      assert {:error, %Ecto.Changeset{}} = SourceFeeds.update_feed(feed, @invalid_attrs)
      assert feed == SourceFeeds.get_feed!(feed.id)
    end

    test "delete_feed/1 deletes the feed" do
      feed = feed_fixture()
      assert {:ok, %Feed{}} = SourceFeeds.delete_feed(feed)
      assert_raise Ecto.NoResultsError, fn -> SourceFeeds.get_feed!(feed.id) end
    end

    test "change_feed/1 returns a feed changeset" do
      feed = feed_fixture()
      assert %Ecto.Changeset{} = SourceFeeds.change_feed(feed)
    end
  end
end
