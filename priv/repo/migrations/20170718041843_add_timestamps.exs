defmodule Stockboard.Repo.Migrations.AddTimestamps do
  use Ecto.Migration

  def change do
    alter table(:histories) do
      timestamps()
    end
  end
end
