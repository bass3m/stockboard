defmodule Stockboard.StockController do
  use Stockboard.Web, :controller
  import Ecto.Query, only: [from: 2]
  import Ecto.Query.API, only: [ago: 2]
  alias Stockboard.Stock
  alias Stockboard.Main
  alias Stockboard.Repo
  alias Stockboard.History
  alias Stockboard.Api
  require Logger


  def index(conn, _params) do
    stocks = Repo.all(Stock)
    render(conn, "index.html", stocks: stocks)
  end

  def new(conn, _params) do
    changeset = Stock.changeset(%Stock{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"stock" => stock_params}) do
    changeset = Stock.changeset(%Stock{}, stock_params)

    case Repo.insert(changeset) do
      {:ok, stock} ->
        # start the worker
        Main.add_stock(stock)
        conn
        |> put_flash(:info, "Stock created successfully.")
        |> redirect(to: stock_path(conn, :index))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    stock = Repo.get!(Stock, id)
    render(conn, "show.html", stock: stock)
  end

  def edit(conn, %{"id" => id}) do
    stock = Repo.get!(Stock, id)
    changeset = Stock.changeset(stock)
    render(conn, "edit.html", stock: stock, changeset: changeset)
  end

  def update(conn, %{"id" => id, "stock" => stock_params}) do
    stock = Repo.get!(Stock, id)
    changeset = Stock.changeset(stock, stock_params)

    case Repo.update(changeset) do
      {:ok, stock} ->
        Main.update_stock(stock)
        conn
        |> put_flash(:info, "Stock updated successfully.")
        |> redirect(to: stock_path(conn, :show, stock))
      {:error, changeset} ->
        render(conn, "edit.html", stock: stock, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    stock = Repo.get!(Stock, id)

    # stop the worker and delete stock history
    Main.delete_stock(stock)
    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(stock)

    conn
    |> put_flash(:info, "Stock deleted successfully.")
    |> redirect(to: stock_path(conn, :index))
  end

  def history(conn, %{"id" => id}) do
    stock = Repo.get!(Stock, id)
    #render(conn, "history.html", stock: stock)
    render(conn, "history.html", id: id)
  end

  defp get_history_for_interval(stock_symbol, interval) do
    [how_many, time_unit] = String.split(interval, "_")
    how_many = Integer.parse(how_many) |> elem(0)
    stock = Repo.get_by!(Stock, symbol: stock_symbol)
    query = from h in History, where: h.stock_id == ^stock.id
    count_query = from h in History, select: count(h.id)
    case Repo.all(count_query) do
      [0] ->
        Logger.info("Get entries for: #{inspect stock_symbol} nothing to show, table empty")
        []
      _ ->
        query = from(h in query,
        where: not(is_nil(h.updated_at)) and h.updated_at > ago(^how_many, ^time_unit),
        select: [h.price, h.updated_at])
        stock_history = Repo.all(query)
        Logger.debug("Get db for stock #{inspect stock_symbol} interval #{inspect interval}")
        Logger.debug("History results for stock #{inspect stock_symbol} : #{inspect stock_history}")
        stock_history
    end
  end

  def interval(conn, %{"id" => id, "interval" => interval} = stock_params) do
    stock = Repo.get!(Stock, id)
    Logger.info "interval request for id #{inspect id} stock #{inspect stock_params} interval #{inspect interval}"
    history = get_history_for_interval(stock.symbol, interval["interval"])
    Stockboard.Endpoint.broadcast!("metrics:stockboard", "new_msg",
      %{metric: "historical_stock_data", body: %{symbol: String.upcase(stock.symbol),
                                                 exchange: String.upcase(stock.exchange),
                                                 prices: Enum.map(history, fn h -> List.first(h) end),
                                                 timestamps: Enum.map(history, fn h -> List.last(h) end),
                                                 type: "table"}})
    render(conn, "history.html", id: id)
  end
end
