defmodule Stockboard.Router do
  use Stockboard.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", Stockboard do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
    resources "/stocks", StockController
    get "/history/:id", StockController, :history
    #post "/interval/:id", StockController, :interval
  end

  # Other scopes may use custom stacks.
  # scope "/api", Stockboard do
  #   pipe_through :api
  # end
end
