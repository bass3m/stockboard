defmodule Stockboard.Main do
  use GenServer
  alias Stockboard.Repo
  alias Stockboard.Stock
  alias Stockboard.Api
  require Logger
  @name :main

  def start_link() do
    {:ok, httpoison} = HTTPoison.start()
    GenServer.start_link(__MODULE__, %{:httpoison => httpoison,
                                       :stock_uri => "",
                                       :server_reqs_sent => 0,
                                       :server_ok => 0,
                                       :server_error => 0,
                                       :server_other => 0,
                                       :server_no_data => 0,
                                       :dns_error => 0,
                                       :timeout_error => 0,
                                       :timeout => 10_000,
                                       :workers => [],
                                       :timer_ref => nil}, name: @name)
  end

  def status() do
    GenServer.call(@name, :status)
  end

  def add_stock(stock) do
    GenServer.call(@name, {:add_worker, stock})
  end

  def delete_stock(stock) do
    GenServer.call(@name, {:delete_worker, stock})
  end

  def update_stock(stock) do
    GenServer.call(@name, {:update_worker, stock})
  end

  def init(state) do
    stocks = Repo.all(Stock)
    # want to start linked processes
    workers =
      Enum.reduce(stocks, [],
        fn(stock, acc) ->
          [%{pid: Process.spawn(Stockboard.Worker, :stock_worker, [stock], [:link]),
             stock_id: stock.id} | acc] end)
    Process.send(self(), :call_api, [])
    {:ok, %{state | workers: workers}}
  end

  def handle_call(:status, _from, state) do
    Logger.info "rcvd status msg: #{inspect state}"
    {:reply, state, state}
  end

  def handle_call({:delete_worker, stock}, _from, state) do
    Logger.info "Stopping worker for stock #{inspect stock}"
    case Enum.find(state.workers, fn(w) -> w[:stock_id] == stock.id end) do
      worker when is_map(worker)  ->
        Logger.info "found worker process to delete #{inspect worker}"
        stop_worker(worker)
        {:reply,
         {:ok, :worker_stopped},
         %{state |
           workers: Enum.reject(state.workers, fn(w) -> w[:stock_id] == stock.id end)}}
      _ ->
        Logger.error "Unable to find worker process to delete"
        {:reply, {:error, :worker_not_found}, state}
    end
  end

  def handle_call({:add_worker, stock}, _from, state) do
    Logger.info "Starting worker for stock #{inspect stock}"
    {:reply, {:ok, :worker_started},
     %{state |
       workers: [%{pid: Process.spawn(Stockboard.Worker, :stock_worker, [stock], [:link]),
                   stock_id: stock.id} | state.workers]}}
  end

  def handle_call({:update_worker, stock}, _from, state) do
    Logger.info "Updating worker for stock #{inspect stock}"
    case Enum.find(state.workers, fn(w) -> w[:stock_id] == stock.id end) do
      worker when is_map(worker)  ->
        Logger.info "found worker process to update #{inspect worker}"
        update_worker(worker, stock)
        {:reply,
         {:ok, :worker_updated}, state}
      _ ->
        Logger.error "Unable to find worker process to update"
        {:reply, {:error, :worker_not_found}, state}
    end
  end

  def handle_info(:call_api, state) do
    {:ok, _id} = Api.call_api()
    {:noreply, %{state | server_reqs_sent:  state.server_reqs_sent + 1}}
  end

  def handle_info({:timeout, timer_ref, :call_api}, %{timer_ref: timer_ref} = state) do
    {:ok, _id} = Api.call_api()
    {:noreply, %{state | server_reqs_sent:  state.server_reqs_sent + 1}}
  end

  def handle_info(%HTTPoison.AsyncStatus{code: 500}, state) do
    Logger.debug "API returned error 500"
    {:noreply, %{state | server_error: state.server_error + 1}}
  end

  def handle_info(%HTTPoison.AsyncStatus{code: 200}, state) do
    #Logger.debug "API returned success."
    {:noreply, %{state | server_ok: state.server_ok + 1}}
  end

  def handle_info(%HTTPoison.AsyncStatus{code: code}, state) do
    Logger.debug "API returned: #{inspect code}"
    {:noreply, %{state | server_other: state.server_other + 1}}
  end

  def handle_info(%HTTPoison.AsyncChunk{chunk: "{}"}, state) do
    Logger.debug "Got no data back from server"
    timer_ref = :erlang.start_timer(state.timeout, self(), :call_api)
    {:noreply, %{state | timer_ref: timer_ref, server_no_data: state.server_no_data + 1}}
  end

  def handle_info(%HTTPoison.AsyncChunk{chunk: data}, state) do
    sector_data = parse_sector_data(data)
    Logger.debug "Realtime sector data: #{inspect sector_data}"
    timer_ref = :erlang.start_timer(state.timeout, self(), :call_api)
    Stockboard.Endpoint.broadcast!("metrics:stockboard", "new_msg",
      %{metric: "realtime_sector_data", body: %{title: "Realtime Sector Data",
                                                type: "timeseries",
                                                labels: Map.keys(sector_data),
                                                dataset:
                                                sector_data
                                                |> Map.values()
                                                |> Enum.map(fn s -> String.replace(s, "%", "") end)}})
    {:noreply, %{state | timer_ref: timer_ref}}
  end

  def handle_info({:error, %HTTPoison.Error{id: nil, reason: :nxdomain}}, state) do
    Logger.debug "API DNS error"
    timer_ref = :erlang.start_timer(state.timeout, self(), :call_api)
    {:noreply, %{state | timer_ref: timer_ref, dns_error: state.dns_error + 1}}
  end

  def handle_info(%HTTPoison.Error{id: _id, reason: {:closed, :timeout}},state) do
    Logger.debug "API timeout error"
    timer_ref = :erlang.start_timer(state.timeout, self(), :call_api)
    {:noreply, %{state | timer_ref: timer_ref, timeout_error: state.timeout_error + 1}}
  end

  def handle_info(_info, state) do
    #Logger.debug "Info received: #{inspect info}"
    {:noreply, state}
  end

  def parse_sector_data(sector_data) do
    {:ok, json_sector_data} = Poison.decode(sector_data)
    # we're only interested in realtime data
    json_sector_data["Rank A: Real-Time Performance"]
  end

  def stop_worker(worker) do
    if Process.alive?(worker.pid) do
      Logger.info "Process #{inspect worker.pid} is alive. Sending exit"
      send(worker.pid, {:worker_stop, self(), :stock_deleted})
    else
      Logger.error "Worker pid is not alive: #{inspect worker}"
    end
  end

  def update_worker(worker, stock) do
    if Process.alive?(worker.pid) do
      Logger.info "Process #{inspect worker.pid} is alive. Sending update message"
      send(worker.pid, {:worker_update, self(), stock})
    else
      Logger.error "Worker pid is not alive: #{inspect worker}"
    end
  end
end
