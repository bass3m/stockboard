defmodule Stockboard.PageController do
  use Stockboard.Web, :controller
  alias Stockboard.Stock

  require Logger

  def index(conn, _params) do
    # grab config for layout
    layout_cfg = Application.get_env(:stockboard, LayoutConfig)
    # need template for nav, sidebar and index
    stocks = Repo.all(Stock)
    Logger.info("stocks #{inspect stocks}")

    conn
    |> assign(:layout_cfg, layout_cfg)
    |> assign(:stocks, stocks)
    |> render("index.html")
  end
end
