defmodule Pheeds.Repo.Migrations.AddExtraXpathExpressions do
  use Ecto.Migration

  def change do
    rename table(:feeds), :xpath_expression, to: :items_xpath

    alter table(:feeds) do
      add :title_xpath, :string
      add :link_xpath, :string
      add :date_xpath, :string
    end
  end
end
