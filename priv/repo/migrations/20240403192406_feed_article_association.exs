defmodule Pheeds.Repo.Migrations.FeedArticleAssociation do
  use Ecto.Migration

  def change do
    alter table(:feed_articles) do
      add :feed_id, references(:feeds, on_delete: :delete_all)
    end
  end
end
