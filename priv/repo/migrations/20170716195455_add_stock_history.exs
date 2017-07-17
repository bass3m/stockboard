defmodule Stockboard.Repo.Migrations.AddStockHistory do
  use Ecto.Migration

  def change do
    create table(:histories) do
      add :price, :float
      add :volume, :integer
      add :price_hi, :float
      add :price_low, :float
      add :stock_id, references(:stocks, on_delete: :nothing)
    end

  end
end
