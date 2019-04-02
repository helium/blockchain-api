defmodule BlockchainAPI.Query.AccountTransaction do
  @moduledoc false
  import Ecto.Query, warn: false
  @default_limit 100

  alias BlockchainAPI.{
    Repo,
    Util,
    Query,
    Schema.Block,
    Schema.AccountTransaction,
    Schema.Transaction,
    Schema.PaymentTransaction,
    Schema.CoinbaseTransaction,
    Schema.GatewayTransaction,
    Schema.LocationTransaction,
    Schema.Hotspot,
    Schema.Account,
    Schema.PendingLocation,
    Schema.PendingGateway,
    Schema.PendingPayment,
    Schema.PendingCoinbase
  }

  def create(attrs \\ %{}) do
    %AccountTransaction{}
    |> AccountTransaction.changeset(attrs)
    |> Repo.insert()
  end

  def list(address, %{"before" => before, "limit" => limit}=_params) do
    address
    |> list_query()
    |> filter_before(before, limit)
    |> Repo.all()
    |> format()
    |> IO.inspect()
  end
  def list(address, %{"before" => before}=_params) do
    address
    |> list_query()
    |> filter_before(before, @default_limit)
    |> Repo.all()
    |> format()
    |> IO.inspect()
  end
  def list(address, %{"limit" => limit}=_params) do
    address
    |> list_query()
    |> limit(^limit)
    |> Repo.all()
    |> format()
    |> IO.inspect()
  end
  def list(address, %{}) do
    address
    |> list_query()
    |> Repo.all()
    |> format()
    |> IO.inspect()
  end

  def get_pending_txn!(txn_hash) do
    AccountTransaction
    |> where([at], at.txn_hash == ^txn_hash)
    |> where([at], at.txn_status == "pending")
    |> Repo.one!
  end

  def update_pending!(pending, attrs \\ %{}) do
    pending
    |> AccountTransaction.changeset(attrs)
    |> Repo.update!()
  end

  def delete_pending!(pending, attrs \\ %{}) do
    pending
    |> AccountTransaction.changeset(attrs)
    |> Repo.delete!()
  end

  def get_gateways(address, params \\ %{}) do
    query = from(
      at in AccountTransaction,
      where: at.account_address == ^address,
      left_join: gt in GatewayTransaction,
      on: at.account_address == gt.owner,
      left_join: hotspot in Hotspot,
      on: at.account_address == hotspot.owner,
      where: gt.gateway == hotspot.address,
      where: gt.owner == hotspot.owner,
      where: at.txn_hash == gt.hash,
      left_join: lt in LocationTransaction,
      on: gt.gateway == lt.gateway,
      distinct: hotspot.address,
      order_by: [desc: lt.nonce, desc: hotspot.id],
      select: %{
        account_address: at.account_address,
        gateway: gt.gateway,
        gateway_hash: gt.hash,
        gateway_fee: gt.fee,
        owner: gt.owner,
        location: lt.location,
        location_fee: lt.fee,
        location_nonce: lt.nonce,
        location_hash: lt.hash,
        long_city: hotspot.long_city,
        long_street: hotspot.long_street,
        long_state: hotspot.long_state,
        long_country: hotspot.long_country,
        short_city: hotspot.short_city,
        short_street: hotspot.short_street,
        short_state: hotspot.short_state,
        short_country: hotspot.short_country,
      })

    query
    |> Repo.all()
    |> clean_account_gateways()
  end

  #==================================================================
  # Helper functions
  #==================================================================
  defp clean_account_gateways(entries) do
    entries
    |> Enum.map(fn map ->
      {lat, lng} = Util.h3_to_lat_lng(map.location)
      map
      |> encoded_account_gateway_map()
      |> Map.merge(%{lat: lat, lng: lng})
    end)
  end

  defp encoded_account_gateway_map(map) do
    %{map |
      account_address: Util.bin_to_string(map.account_address),
      gateway: Util.bin_to_string(map.gateway),
      gateway_hash: Util.bin_to_string(map.gateway_hash),
      location_hash: Util.bin_to_string(map.location_hash),
      owner: Util.bin_to_string(map.owner)
    }
  end

  defp list_query(address) do
    pending = list_pending(address)
    cleared = list_cleared(address)

    query = Ecto.Query.union(pending, ^cleared)

    from(
      q in subquery(query),
      order_by: [desc: q.id]
    )
  end

  defp list_pending(address) do
    three_hours_ago = Timex.to_naive_datetime(Timex.shift(Timex.now(), hours: -3))

    from(
      at in AccountTransaction,
      where: at.account_address == ^address,
      where: at.txn_status == "pending",
      where: at.inserted_at >= ^three_hours_ago
    )
  end

  defp list_cleared(address) do
    from(
      at in AccountTransaction,
      where: at.account_address == ^address,
      where: at.txn_status == "cleared"
    )
  end

  defp filter_before(query, before, limit) do
    query
    |> where([at], at.inserted_at < ^before)
    |> limit(^limit)
  end

  defp format(entries) do
    entries
    |> Enum.map(
      fn(entry) ->
        case entry.txn_status do
          "cleared" ->
            case entry.txn_type do
              "payment" ->
                entry.txn_hash
                |> Query.Transaction.get_payment!()
                |> PaymentTransaction.encode_model()
              "coinbase" ->
                entry.txn_hash
                |> Query.Transaction.get_coinbase!()
                |> CoinbaseTransaction.encode_model()
              "gateway" ->
                entry.txn_hash
                |> Query.Transaction.get_gateway!()
                |> GatewayTransaction.encode_model()
              "location" ->
                entry.txn_hash
                |> Query.Transaction.get_location!()
                |> LocationTransaction.encode_model()
            end
          "pending" ->
            case entry.txn_type do
              "payment" ->
                Query.PendingPayment.get!(entry.txn_hash)
              "coinbase" ->
                Query.PendingCoinbase.get!(entry.txn_hash)
              "gateway" ->
                Query.PendingGateway.get!(entry.txn_hash)
              "location" ->
                Query.PendingLocation.get!(entry.txn_hash)
            end
        end
      end
    )
  end
end
