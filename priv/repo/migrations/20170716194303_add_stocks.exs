defmodule Stockboard.Repo.Migrations.AddStocks do
  use Ecto.Migration

  def change do
    create table(:stocks) do
      add :symbol, :string
      add :exchange, :string
      add :name, :string
      add :update_every, :integer
      add :save_every_mins, :integer
      add :keep_for_days, :integer

      timestamps()
    end

  end
end
