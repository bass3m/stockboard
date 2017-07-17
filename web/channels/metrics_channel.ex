defmodule Stockboard.MetricsChannel do
  use Phoenix.Channel

  def join("metrics:stockboard", _message, socket) do
    {:ok, socket}
  end
end
