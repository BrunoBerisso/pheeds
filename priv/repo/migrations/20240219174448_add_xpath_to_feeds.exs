defmodule Pheeds.Repo.Migrations.AddXpathToFeeds do
  use Ecto.Migration

  def change do

    alter table(:feeds) do
      add :xpath_expression, :string
    end

  end
end
