defmodule Pheeds.SourceFeeds.Feed do
  use Ecto.Schema
  import Ecto.Changeset

  @status_error    -1
  @status_ok       0
  @status_updating 1

  schema "feeds" do
    field :status, :integer, default: 0
    field :title, :string
    field :url, :string
    field :last_update, :naive_datetime
    field :xpath_expression, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(feed, attrs) do
    feed
    |> cast(attrs, [:title, :url, :last_update, :status, :xpath_expression])
    |> validate_required([:title, :url])
  end

  def status(%{status: status}) do
    case status do
      @status_error      -> :error
      [nil | @status_ok] -> :ok
      @status_updating   -> :updating
      _ -> :unknown
    end
  end

  def status(feed_status) do
    case feed_status do
      :error  -> @status_error
      :ok     -> @status_ok
      :updating -> @status_updating
    end
  end

end
