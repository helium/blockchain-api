defmodule BlockchainAPI.Query.HotspotActivity do
  @moduledoc false
  import Ecto.Query, warn: false

  @default_limit 100

  alias BlockchainAPI.{Repo, Util, Schema.HotspotActivity}

  def create(attrs \\ %{}) do
    %HotspotActivity{}
    |> HotspotActivity.changeset(attrs)
    |> Repo.insert()
  end

  def last_poc_score(address) do
    from(
      ha in HotspotActivity,
      where: ha.gateway == ^address,
      where: not is_nil(ha.poc_rx_txn_block_height),
      order_by: [desc: ha.id],
      select: ha.poc_score,
      limit: 1
    )
    |> Repo.one()
  end

  def activity_for(address, %{"before" => before, "limit" => limit}=_params) do
    address
    |> activity_query()
    |> filter_before(before, limit)
    |> Repo.all()
    |> encode()
  end
  def activity_for(address, %{"before" => before}=_params) do
    address
    |> activity_query()
    |> filter_before(before, @default_limit)
    |> Repo.all()
    |> encode()
  end
  def activity_for(address, %{"limit" => limit}=_params) do
    address
    |> activity_query()
    |> limit(^limit)
    |> Repo.all()
    |> encode()
  end
  def activity_for(address, %{}) do
    address
    |> activity_query()
    |> Repo.all()
    |> encode()
  end

  defp activity_query(address) do
    HotspotActivity
    |> where([ha], ha.gateway == ^address)
    |> order_by([ha], [desc: ha.id])
  end

  defp filter_before(query, before, limit) do
    query
    |> where([ha], ha.id < ^before)
    |> limit(^limit)
  end

  defp encode([]), do: []
  defp encode(entries) do
    entries |> Enum.map(&encode_entry/1)
  end

  defp encode_entry(entry) do
    poc_req_txn_hash =
      case entry.poc_req_txn_hash do
        nil -> nil
        hash -> Util.bin_to_string(hash)
      end

    poc_rx_txn_hash =
      case entry.poc_rx_txn_hash do
        nil -> nil
        hash -> Util.bin_to_string(hash)
      end

    %{
      id: entry.id,
      gateway: Util.bin_to_string(entry.gateway),
      poc_req_txn_block_height: entry.poc_req_txn_block_height,
      poc_req_txn_block_time: entry.poc_req_txn_block_time,
      poc_rx_txn_block_height: entry.poc_rx_txn_block_height,
      poc_rx_txn_block_time: entry.poc_rx_txn_block_time,
      poc_rx_id: entry.poc_rx_id,
      poc_witness_id: entry.poc_witness_id,
      poc_rx_txn_hash: poc_rx_txn_hash,
      poc_req_txn_hash: poc_req_txn_hash,
      poc_witness_challenge_id: entry.poc_witness_challenge_id,
      poc_rx_challenge_id: entry.poc_rx_challenge_id,
      poc_score: entry.poc_score,
      poc_score_delta: entry.poc_score_delta,
      rapid_decline: entry.rapid_decline
    }
  end
end
