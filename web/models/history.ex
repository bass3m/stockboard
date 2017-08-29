defmodule Stockboard.History do
  use Stockboard.Web, :model

  schema "histories" do
    field :price, :float
    field :volume, :integer
    field :price_hi, :float
    field :price_low, :float
    belongs_to :stock, Stockboard.Stock

    timestamps(type: :utc_datetime)
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:price, :volume, :price_low, :price_hi])
    |> validate_required([:price, :volume, :price_low, :price_hi])
  end
end
