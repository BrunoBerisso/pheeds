defmodule Pheeds.Repo.Migrations.CreateFeeds do
  use Ecto.Migration

  def change do
    create table(:feeds) do
      add :title, :string
      add :url, :string
      add :last_update, :naive_datetime
      add :status, :integer

      timestamps(type: :utc_datetime)
    end
  end
end
