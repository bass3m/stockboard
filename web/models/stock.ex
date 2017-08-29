defmodule Stockboard.Stock do
  use Stockboard.Web, :model

  schema "stocks" do
    field :symbol, :string
    field :exchange, :string
    field :name, :string
    field :update_every, :integer
    field :save_every_mins, :integer
    field :keep_for_days, :integer
    has_many :histories, Stockboard.History, on_delete: :delete_all

    timestamps(type: :utc_datetime)
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:symbol, :exchange, :name, :update_every, :save_every_mins, :keep_for_days])
    |> validate_required([:symbol, :exchange, :name, :update_every, :save_every_mins, :keep_for_days])
    |> unique_constraint(:symbol)
    |> validate_inclusion(:update_every, 5..300) # seconds
    |> validate_inclusion(:save_every_mins, 30..300) # minutes
    |> validate_inclusion(:keep_for_days, 1..365) # days
  end
end
