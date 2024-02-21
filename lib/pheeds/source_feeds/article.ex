defmodule Pheeds.SourceFeeds.Article do
  use Ecto.Schema
  import Ecto.Changeset

  schema "feed_articles" do
    field :link, :string
    field :title, :string
    field :published_date, :naive_datetime

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(article, attrs) do
    article
    |> cast(attrs, [:title, :link, :published_date])
    |> validate_required([:title, :link, :published_date])
  end

  def parse_published_date!(string_date) do
    string_date |> String.split(" ") |> Enum.with_index |> Enum.reduce(&(build_iso8601/2)) |> NaiveDateTime.from_iso8601!
  end

  # Sun, 11 Feb 2024 00:44:37 +0000
  defp build_iso8601(date_comp, str_acc) do
    case date_comp do
      {v, 1} -> v
      {v, 2} -> month_name_to_pos(v) <> "-" <> str_acc
      {v, 3} -> v <> "-" <> str_acc
      {v, 4} -> str_acc <> "T" <> v
      {v, 5} -> str_acc <> (if String.starts_with?(v, "+"), do: v, else: "+0000")
      _ -> str_acc
    end
  end

  # month     =  "Jan"  /  "Feb" /  "Mar"  /  "Apr"
  #           /  "May"  /  "Jun" /  "Jul"  /  "Aug"
  #           /  "Sep"  /  "Oct" /  "Nov"  /  "Dec"
  defp month_name_to_pos(month_name) do
    case month_name do
      "Jan" -> "01"
      "Feb" -> "02"
      "Mar" -> "03"
      "Apr" -> "04"
      "May" -> "05"
      "Jun" -> "06"
      "Jul" -> "07"
      "Aug" -> "08"
      "Sep" -> "09"
      "Oct" -> "10"
      "Nov" -> "11"
      "Dec" -> "12"
    end
  end
end
