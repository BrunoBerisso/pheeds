defmodule Pheeds.SourceFeeds do
  @moduledoc """
  The SourceFeeds context.
  """

  @seconds_in_a_day 86400

  import Ecto.Query, warn: false
  import NaiveDateTime
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
    query = from f in Feed, where: (f.status == ^Feed.status(:ok) and ^add(local_now(), -@seconds_in_a_day) <= f.last_update) or is_nil(f.last_update)
    Repo.all(query)
  end

  def start_updating!(feed) do
     feed
      |> Feed.changeset(%{status: Feed.status(:updating)})
      |> Repo.update!()
  end

  def end_updating!(feed) do
     feed
      |> Feed.changeset(%{status: Feed.status(:ok), last_update: NaiveDateTime.local_now()})
      |> Repo.update!()
  end

  def eror_updating!(feed) do
    feed
     |> Feed.changeset(%{status: Feed.status(:error)})
     |> Repo.update!()
  end

end
