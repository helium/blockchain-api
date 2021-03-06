defmodule BlockchainAPIWeb.GatewayController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPI.{Util, Query}
  import BlockchainAPI.Cache.CacheService

  action_fallback BlockchainAPIWeb.FallbackController

  def index(conn, params) do
    gateways = Query.GatewayTransaction.list(params)

    conn
    |> put_cache_headers(ttl: :short, key: "block")
    |> render("index.json", gateways: gateways)
  end

  def show(conn, %{"hash" => hash}) do
    gateway =
      hash
      |> Util.string_to_bin()
      |> Query.GatewayTransaction.get!()

    conn
    |> put_cache_headers(ttl: :short, key: "block")
    |> render("show.json", gateway: gateway)
  end
end
