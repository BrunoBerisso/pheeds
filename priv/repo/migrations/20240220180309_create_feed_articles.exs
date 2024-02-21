defmodule Pheeds.Repo.Migrations.CreateFeedArticles do
  use Ecto.Migration

  def change do
    create table(:feed_articles) do
      add :title, :string
      add :link, :string
      add :published_date, :naive_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:feed_articles, [:link])
  end
end
