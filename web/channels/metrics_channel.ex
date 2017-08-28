defmodule Stockboard.MetricsChannel do
  use Phoenix.Channel
  import Ecto.Query, only: [from: 2]
  import Ecto.Query.API, only: [ago: 2]
  alias Stockboard.Stock
  alias Stockboard.Repo
  alias Stockboard.History
  require Logger

  def join("metrics:stockboard", _message, socket) do
    {:ok, socket}
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
        order_by: [asc: h.updated_at],
        select: [h.price, h.updated_at])
        stock_history = Repo.all(query)
        Logger.debug("Get db for stock #{inspect stock_symbol} interval #{inspect interval}")
        Logger.debug("History results for stock #{inspect stock_symbol} : #{inspect stock_history}")
        stock_history
    end
  end

  def handle_in("new_msg", params, socket) do
    {:ok, params} = Poison.decode(params)
    Logger.info "Rcvd ws msg: #{inspect params}"
    with stock_id <- params["stock"],
         interval <- params["value"],
         stock <- Repo.get!(Stock, stock_id),
         history <- get_history_for_interval(stock.symbol, interval)
    do
      Stockboard.Endpoint.broadcast!("metrics:stockboard", "new_msg",
        %{metric: "historical_stock_data",
          body: %{symbol: String.upcase(stock.symbol),
                  exchange: String.upcase(stock.exchange),
                  prices: Enum.map(history, fn h -> List.first(h) end),
                  timestamps: Enum.map(history, fn h -> List.last(h) end),
                  type: "table"}})
    {:reply, :ok, socket}
    end
  end
end
