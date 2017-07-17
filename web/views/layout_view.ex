defmodule Stockboard.LayoutView do
  use Stockboard.Web, :view

  def layout_cfg() do
    # grab config for layout
    cfg = Application.get_env(:stockboard, LayoutConfig)
    cfg
  end

  def navbar() do
    cfg = layout_cfg()
    cfg[:nav]
  end

  def sidebar() do
    cfg = layout_cfg()
    cfg[:sidebar]
  end
end
