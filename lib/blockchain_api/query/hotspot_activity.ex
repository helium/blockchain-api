defmodule BlockchainAPI.Query.HotspotActivity do
  @moduledoc """
  Hotspot Activity query functions.
  """

  import Ecto.Query, warn: false

  @default_limit 100
  @max_limit 500

  alias BlockchainAPI.{Repo, Util, Schema.HotspotActivity}

  @doc false
  def create(attrs \\ %{}) do
    %HotspotActivity{}
    |> HotspotActivity.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Get last poc score of given hotspot `address`.
  """
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

  @doc """
  List hotspot `address` activity information.

  Filter by `params`.
  """
  def list(address, params) do
    address
    |> activity_query()
    |> maybe_filter(params)
    |> Repo.all()
    |> encode()
  end

  defp activity_query(address) do
    HotspotActivity
    |> where([ha], ha.gateway == ^address)
    |> order_by([ha], desc: ha.id)
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
      rapid_decline: entry.rapid_decline,
      in_consensus: entry.in_consensus,
      election_id: entry.election_id,
      election_txn_block_height: entry.election_txn_block_height,
      election_block_height: entry.election_block_height,
      election_txn_block_time: entry.election_txn_block_time,
      reward_type: entry.reward_type,
      reward_amount: entry.reward_amount,
      reward_block_height: entry.reward_block_height,
      reward_block_time: entry.reward_block_time
    }
  end

  defp maybe_filter(query, %{"before" => before, "limit" => limit0} = _params) do
    limit = min(@max_limit, String.to_integer(limit0))

    query
    |> where([ha], ha.id < ^before)
    |> limit(^limit)
  end

  defp maybe_filter(query, %{"before" => before} = _params) do
    query
    |> where([ha], ha.id < ^before)
    |> limit(@default_limit)
  end

  defp maybe_filter(query, %{"limit" => limit0} = _params) do
    limit = min(@max_limit, String.to_integer(limit0))

    query
    |> limit(^limit)
  end

  defp maybe_filter(query, %{}) do
    query
    |> limit(@default_limit)
  end
end
