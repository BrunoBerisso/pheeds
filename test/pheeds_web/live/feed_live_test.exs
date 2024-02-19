defmodule PheedsWeb.FeedLiveTest do
  use PheedsWeb.ConnCase

  import Phoenix.LiveViewTest
  import Pheeds.SourceFeedsFixtures

  @create_attrs %{status: 42, title: "some title", url: "some url", last_update: "2024-02-18T16:12:00"}
  @update_attrs %{status: 43, title: "some updated title", url: "some updated url", last_update: "2024-02-19T16:12:00"}
  @invalid_attrs %{status: nil, title: nil, url: nil, last_update: nil}

  defp create_feed(_) do
    feed = feed_fixture()
    %{feed: feed}
  end

  describe "Index" do
    setup [:create_feed]

    test "lists all feeds", %{conn: conn, feed: feed} do
      {:ok, _index_live, html} = live(conn, ~p"/feeds")

      assert html =~ "Listing Feeds"
      assert html =~ feed.title
    end

    test "saves new feed", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/feeds")

      assert index_live |> element("a", "New Feed") |> render_click() =~
               "New Feed"

      assert_patch(index_live, ~p"/feeds/new")

      assert index_live
             |> form("#feed-form", feed: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#feed-form", feed: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/feeds")

      html = render(index_live)
      assert html =~ "Feed created successfully"
      assert html =~ "some title"
    end

    test "updates feed in listing", %{conn: conn, feed: feed} do
      {:ok, index_live, _html} = live(conn, ~p"/feeds")

      assert index_live |> element("#feeds-#{feed.id} a", "Edit") |> render_click() =~
               "Edit Feed"

      assert_patch(index_live, ~p"/feeds/#{feed}/edit")

      assert index_live
             |> form("#feed-form", feed: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#feed-form", feed: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/feeds")

      html = render(index_live)
      assert html =~ "Feed updated successfully"
      assert html =~ "some updated title"
    end

    test "deletes feed in listing", %{conn: conn, feed: feed} do
      {:ok, index_live, _html} = live(conn, ~p"/feeds")

      assert index_live |> element("#feeds-#{feed.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#feeds-#{feed.id}")
    end
  end

  describe "Show" do
    setup [:create_feed]

    test "displays feed", %{conn: conn, feed: feed} do
      {:ok, _show_live, html} = live(conn, ~p"/feeds/#{feed}")

      assert html =~ "Show Feed"
      assert html =~ feed.title
    end

    test "updates feed within modal", %{conn: conn, feed: feed} do
      {:ok, show_live, _html} = live(conn, ~p"/feeds/#{feed}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Feed"

      assert_patch(show_live, ~p"/feeds/#{feed}/show/edit")

      assert show_live
             |> form("#feed-form", feed: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#feed-form", feed: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/feeds/#{feed}")

      html = render(show_live)
      assert html =~ "Feed updated successfully"
      assert html =~ "some updated title"
    end
  end
end
