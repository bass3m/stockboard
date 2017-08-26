defmodule Stockboard.TestWorker do
  require Logger
  alias Stockboard.Repo
  alias Stockboard.Stock
  alias Stockboard.History
  import Ecto.Query, only: [from: 2]
  import Ecto.Query.API, only: [ago: 2]

  def test_worker() do
    Logger.info "Starting test worker"
    state = %{:timer_ref => nil,
              :save_timer_ref => nil, # save stocks timer
              :keep_timer_ref => nil, # every period, trim the table
              :timeout => 5 * 1_000, # in milliseconds
              :save_quote_timeout => 5 * 60 * 1_000, # in milliseconds
              :keep_for_timeout => 10 * 60 * 1_000, # trim every 10 minutes in milliseconds
              :symbol => "test",
              :exchange => "NASDAQ",
              :keep_for_days => 33, # default to 33 days
              :last_quote => nil, # cache the last quote for persisting
              :quotes_saved => 0,
              :quotes_trimmed => 0}
    # add 1 sec to make sure we wait at least that long
    rand_start = :rand.uniform() * 1_000
    |> Kernel.+(1_000)
    |> Float.to_string()
    |> Integer.parse()
    |> elem(0)
    Process.send_after(self(), :call_api, rand_start)
    save_timer_ref = :erlang.start_timer(state.save_quote_timeout, self(), :save_quote)
    keep_timer_ref = :erlang.start_timer(state.keep_for_timeout, self(), :trim_quotes)
    loop(%{state | save_timer_ref: save_timer_ref, keep_timer_ref: keep_timer_ref})
  end

  defp call_api() do
    %{price: Enum.random(1..100) + 0.0,
      volume: Enum.random(100_000..1_000_000),
      price_low: Enum.random(1..100) + 0.0,
      price_hi: Enum.random(1..100) + 0.0}
  end

  defp loop(state) do
    receive do
      :call_api ->
        # only called from start
        new_val = call_api()
        notify_clients(new_val, state.symbol, state.exchange)
        timer_ref = :erlang.start_timer(state.timeout, self(), :call_api)
        Logger.info("Start call api for val #{inspect new_val} state: #{inspect state}")
        loop(%{state | timer_ref: timer_ref, last_quote: new_val})
      {:timeout, _timer_ref, :call_api} ->
        new_val = call_api()
        notify_clients(new_val, state.symbol, state.exchange)
        Logger.info("Call api for val #{inspect new_val} state: #{inspect state}")
        timer_ref = :erlang.start_timer(state.timeout, self(), :call_api)
        loop(%{state | timer_ref: timer_ref, last_quote: new_val})
      {:timeout, _save_timer_ref, :save_quote} ->
        # save quote to db
        save_stock_history(state.last_quote, state.symbol)
        save_timer_ref = :erlang.start_timer(state.save_quote_timeout, self(), :save_quote)
        loop(%{state | quotes_saved: state.quotes_saved + 1, save_timer_ref: save_timer_ref})
      {:timeout, _keep_timer_ref, :trim_quotes} ->
        keep_timer_ref = :erlang.start_timer(state.keep_for_timeout, self(), :trim_quotes)
        # trim entries from db
        trim_db_entries(state.symbol, state.keep_for_days)
        loop(%{state | quotes_trimmed: state.quotes_trimmed + 1, keep_timer_ref: keep_timer_ref})
      {:worker_stop, from, reason} ->
        # deleting stock should delete history as well since it's an association
        Logger.info("worker stop from: #{inspect from} reason: #{inspect reason} state: #{inspect state}")
      {:worker_update, from, stock} ->
        Logger.info("worker update from: #{inspect from} new stock: #{inspect stock}")
        loop(%{state |
               timeout: stock.update_every * 1_000, # in milliseconds
               save_quote_timeout: stock.save_every_mins * 60 * 1_000, # in milliseconds
               keep_for_days: stock.keep_for_days})
    end
  end

  def save_stock_history(stock_map, stock_symbol) when is_nil(stock_map) do
    Logger.error("Unable to add history for #{inspect stock_symbol} stock quote is nil")
    stock_map
  end
  def save_stock_history(stock_map, stock_symbol) do
    stock = Repo.get_by!(Stock, symbol: stock_symbol)
    history_entry = Ecto.build_assoc(stock, :histories, stock_map)
    Repo.insert!(history_entry)
    Logger.info "Added history #{inspect history_entry} stock: #{inspect stock} to DB"
    stock_map
  end

  def trim_db_entries(stock_symbol, keep_entries_for_days) do
    Logger.info("Trim entries for #{inspect stock_symbol} older than #{inspect keep_entries_for_days}")
    stock = Repo.get_by!(Stock, symbol: stock_symbol)
    query = from h in History, where: h.stock_id == ^stock.id
    count_query = from h in History, select: count(h.id)
    case Repo.all(count_query) do
      [0] ->
        Logger.info("Trim entries for: #{inspect stock_symbol} nothing to trim, table empty")
      _ ->
        query = from(h in query,
          where: not(is_nil(h.updated_at)) and h.updated_at < ago(^keep_entries_for_days, "day"))
        delete_result = Repo.delete_all(query)
        Logger.debug("Trimmed db for stock #{inspect stock_symbol} with result #{inspect delete_result}")
    end
  end

  def notify_clients(stock_quote_map, symbol, exchange) do
    Logger.info("Notify clients with #{inspect stock_quote_map}")
    Stockboard.Endpoint.broadcast!("metrics:stockboard", "new_msg",
      %{metric: "realtime_stock_data", body: %{symbol: String.upcase(symbol),
                                               exchange: String.upcase(exchange),
                                               price: stock_quote_map.price,
                                               price_low: stock_quote_map.price_low,
                                               price_hi: stock_quote_map.price_hi,
                                               volume: stock_quote_map.volume,
                                               type: "table"}})
    stock_quote_map
  end

end
