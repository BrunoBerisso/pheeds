defmodule Pheeds.SourceFeeds do
  @moduledoc """
  The SourceFeeds context.
  """

  @seconds_in_a_day 86400

  import Ecto.Query, warn: false
  import NaiveDateTime
  alias Phoenix.PubSub
  alias Pheeds.SourceFeeds.Article
  alias Pheeds.Repo
  alias Pheeds.SourceFeeds.Feed

  @doc """
  Returns the list of feeds.

  ## Examples

      iex> list_feeds()
      [%Feed{}, ...]

  """
  def list_feeds do
    Repo.all(Feed)
  end

  @doc """
  Gets a single feed.

  Raises `Ecto.NoResultsError` if the Feed does not exist.

  ## Examples

      iex> get_feed!(123)
      %Feed{}

      iex> get_feed!(456)
      ** (Ecto.NoResultsError)

  """
  def get_feed!(id), do: Repo.get!(Feed, id)

  @doc """
  Creates a feed.

  ## Examples

      iex> create_feed(%{field: value})
      {:ok, %Feed{}}

      iex> create_feed(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_feed(attrs \\ %{}) do
    %Feed{}
    |> Feed.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a feed.

  ## Examples

      iex> update_feed(feed, %{field: new_value})
      {:ok, %Feed{}}

      iex> update_feed(feed, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_feed(%Feed{} = feed, attrs) do
    feed
    |> Feed.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a feed.

  ## Examples

      iex> delete_feed(feed)
      {:ok, %Feed{}}

      iex> delete_feed(feed)
      {:error, %Ecto.Changeset{}}

  """
  def delete_feed(%Feed{} = feed) do
    Repo.delete(feed)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking feed changes.

  ## Examples

      iex> change_feed(feed)
      %Ecto.Changeset{data: %Feed{}}

  """
  def change_feed(%Feed{} = feed, attrs \\ %{}) do
    Feed.changeset(feed, attrs)
  end

  def stale_feeds() do
    query =
      from f in Feed,
        where:
          (f.status == ^Feed.status(:ok) and ^add(utc_now(), -@seconds_in_a_day) <= f.last_update) or
            is_nil(f.last_update)

    Repo.all(query)
  end

  def start_updating!(feed) do
    feed
    |> Feed.changeset(%{status: Feed.status(:updating)})
    |> Repo.update!()

    PubSub.broadcast!(Pheeds.PubSub, "feed_fetcher", {:feed_fetcher, {:start, [{:feed, feed}]}})
  end

  def end_updating!(feed, added_articles) do
    feed
    |> Feed.changeset(%{status: Feed.status(:ok), last_update: utc_now()})
    |> Repo.update!()

    PubSub.broadcast!(
      Pheeds.PubSub,
      "feed_fetcher",
      {:feed_fetcher, {:done, [{:feed, feed}, {:added, added_articles}]}}
    )
  end

  def error_updating!(feed, error_desc) do
    feed
    |> Feed.changeset(%{status: Feed.status(:error)})
    |> Repo.update!()

    PubSub.broadcast!(
      Pheeds.PubSub,
      "feed_fetcher",
      {:feed_fetcher, {:error, [{:feed, feed}, {:error, error_desc}]}}
    )
  end

  def insert_articles!(articles) do
    # :on_conflict :nothing will avoid an exception on duplicated articles, but insert_all might raise
    # error for other reasons. That's why I keept the "!" in the name of this function
    {inserted, _} = Repo.insert_all(Article, articles, [{:on_conflict, :nothing}])
    inserted
  end

  def list_articles_paginated(page, limit \\ 10) when page >= 0 do
    query =
      from f in Article,
        limit: ^limit,
        offset: ^((page - 1) * limit),
        order_by: [desc: :published_date]

    Repo.all(query)
  end
end
