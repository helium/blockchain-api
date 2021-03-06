defmodule BlockchainAPI.Query.GatewayTransaction do
  @moduledoc false
  import Ecto.Query, warn: false

  alias BlockchainAPI.{
    Repo,
    Util,
    Schema.GatewayTransaction,
    Schema.LocationTransaction,
    Schema.Transaction,
    Schema.Hotspot
  }

  def list(_params) do
    query =
      from(
        g in GatewayTransaction,
        left_join: l in LocationTransaction,
        on: g.gateway == l.gateway,
        left_join: h in Hotspot,
        on: g.gateway == h.address,
        select: %{
          gateway: g.gateway,
          gateway_hash: g.hash,
          owner: g.owner,
          payer: g.payer,
          fee: g.fee,
          location: l.location,
          location_fee: l.fee,
          location_nonce: l.nonce,
          location_hash: l.hash,
          score: h.score
        }
      )

    query
    |> Repo.replica.all()
    |> clean_gateways()
  end

  def get!(hash) do
    GatewayTransaction
    |> where([gt], gt.hash == ^hash)
    |> Repo.replica.one!()
  end

  def create(attrs \\ %{}) do
    %GatewayTransaction{}
    |> GatewayTransaction.changeset(attrs)
    |> Repo.insert()
  end

  def get_added_at_height(gateway_address) do
    txn_hash = GatewayTransaction
               |> where([gt], gt.gateway == ^gateway_address)
               |> order_by([gt], gt.id)
               |> limit(1)
               |> select([gt], gt.hash)
               |> Repo.replica.one!()

    Transaction
    |> where([t], t.hash == ^txn_hash)
    |> select([t], t.block_height)
    |> Repo.replica.one!()
  end

  # ==================================================================
  # Helper functions
  # ==================================================================
  defp clean_gateways(entries) do
    entries
    |> Enum.map(fn map ->
      {lat, lng} = Util.h3_to_lat_lng(map.location)

      map
      |> encoded_gateway_map()
      |> Map.merge(%{lat: lat, lng: lng})
    end)
  end

  defp encoded_gateway_map(map) do
    %{
      map
      | gateway: Util.bin_to_string(map.gateway),
        gateway_hash: Util.bin_to_string(map.gateway_hash),
        location_hash: Util.bin_to_string(map.location_hash),
        owner: Util.bin_to_string(map.owner),
        payer: Util.bin_to_string(map.payer),
        score: Util.rounder(map.score, 4)
    }
  end
end
