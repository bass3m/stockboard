defmodule Stockboard.Api do

  defp api_setup() do
    stock_uri = Application.get_env(:stockboard, :stock_uri)
    api_keys = Application.get_env(:stockboard, ApiKeys)
    stock_key = api_keys[:stock_api_key]
    {stock_uri, stock_key}
  end

  def call_api(stock, exchange \\ "NASDAQ") do
    {stock_uri, stock_key} = api_setup()
    {:ok, %HTTPoison.AsyncResponse{id: id}} = HTTPoison.get(stock_uri, [],
      [stream_to: self(),
       params: [function: "GLOBAL_QUOTE", symbol: exchange <> ":" <> stock, apikey: stock_key]])
    {:ok, id}
  end

  def call_api() do
    {stock_uri, stock_key} = api_setup()
    {:ok, %HTTPoison.AsyncResponse{id: id}} = HTTPoison.get(stock_uri, [],
      [stream_to: self(), params: [function: "SECTOR", apikey: stock_key]])
    {:ok, id}
  end
end
