defmodule BlockchainAPI.TestHelpers do
  @moduledoc false

  alias BlockchainAPI.{Query, Util}

  @num_challenges 1000

  def insert_fake_challenges() do
    fake_location = Util.h3_to_string(631_210_983_218_633_727)

    hotspot_map = %{
      address: :crypto.strong_rand_bytes(32),
      owner: :crypto.strong_rand_bytes(32),
      location: fake_location,
      long_city: "San Rafael",
      long_country: "United States",
      long_state: "California",
      long_street: "Las Colindas Road",
      short_city: "San Rafael",
      short_country: "US",
      short_state: "CA",
      short_street: "Las Colindas Rd"
    }

    {:ok, _fake_spot} = Query.Hotspot.create(hotspot_map)

    Range.new(1, @num_challenges)
    |> Enum.map(fn h ->
      block_map = %{hash: :crypto.strong_rand_bytes(32), height: h, round: h, time: h}
      {:ok, b} = Query.Block.create(block_map)

      txn_map = %{
        hash: :crypto.strong_rand_bytes(32),
        type: "doesnt_matter"
      }

      {:ok, t} = Query.Transaction.create(b.height, txn_map)

      gw_map = %{
        owner: :crypto.strong_rand_bytes(32),
        gateway: :crypto.strong_rand_bytes(32),
        fee: 0,
        staking_fee: 0,
        hash: t.hash
      }

      {:ok, g} = Query.GatewayTransaction.create(gw_map)

      request_map = %{
        hash: t.hash,
        signature: :crypto.strong_rand_bytes(32),
        onion: :crypto.strong_rand_bytes(32),
        owner: :crypto.strong_rand_bytes(32),
        challenger: g.gateway,
        location: fake_location,
        fee: 0
      }

      {:ok, r} = Query.POCRequestTransaction.create(request_map)

      challenge_map = %{
        hash: r.hash,
        signature: :crypto.strong_rand_bytes(32),
        onion: :crypto.strong_rand_bytes(32),
        challenger_owner: r.owner,
        challenger: r.challenger,
        challenger_loc: fake_location,
        poc_request_transactions_id: r.id,
        fee: 0
      }

      {:ok, c} = Query.POCReceiptsTransaction.create(challenge_map)
      c
    end)
  end

  @account_valid_attrs %{balance: 1, address: "some address"}

  def account_fixture(attrs \\ %{}) do
    {:ok, account} =
      attrs
      |> Enum.into(@account_valid_attrs)
      |> Query.Account.create()

    account
  end

  def block_fixture(attrs \\ %{}) do
    block_valid_attrs = %{
      hash: :crypto.strong_rand_bytes(32),
      round: :rand.uniform(99_999_999),
      time: Util.current_time(),
      height: :rand.uniform(99_999_999)
    }

    {:ok, block} =
      attrs
      |> Enum.into(block_valid_attrs)
      |> Query.Block.create()

    block
  end
end
