defmodule Pheeds.SourceFeeds.Feed do
  use Ecto.Schema
  import Ecto.Changeset

  schema "feeds" do
    field :status, :integer
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
end
