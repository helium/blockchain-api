defmodule BlockchainAPIWeb.HotspotController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPI.{DBManager, Util}

  action_fallback BlockchainAPIWeb.FallbackController

  def index(conn, params) do
    page = DBManager.list_hotspots(params)

    render(conn,
      "index.json",
      hotspots: page.entries,
      page_number: page.page_number,
      page_size: page.page_size,
      total_pages: page.total_pages,
      total_entries: page.total_entries
    )
  end

  def show(conn, %{"address" => address}) do
    hotspot = address
              |> Util.string_to_bin()
              |> DBManager.get_hotspot!()
    render(conn, "show.json", hotspot: hotspot)
  end

end
