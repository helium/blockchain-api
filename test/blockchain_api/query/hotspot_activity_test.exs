defmodule BlockchainAPI.Query.HotspotActivityTest do
  use BlockchainAPI.DataCase
  import BlockchainAPI.TestHelpers

  alias BlockchainAPI.{
    Query,
    Schema
  }

  setup do
    insert_hotspot_activity()
    :ok
  end

  describe "challenges_witnessed/1" do
    test "returns count of challenges witnessed since last reward" do
      challenges_witnessed =
        from(
          ha in Schema.HotspotActivity,
          where: not is_nil(ha.reward_block_time),
          where: ha.reward_type == ^"poc_witnesses",
          order_by: [desc: ha.reward_block_time],
          limit: 1
        )
        |> Repo.one()
        |> Query.HotspotActivity.challenges_witnessed()

      assert challenges_witnessed == 1
    end
  end

  describe "challenges_completed/1" do
    test "returns count of challenges completed since last reward" do
      challenges_completed =
        from(
          ha in Schema.HotspotActivity,
          where: not is_nil(ha.reward_block_time),
          where: ha.reward_type == ^"poc_challengers",
          order_by: [desc: ha.reward_block_time],
          limit: 1
        )
        |> Repo.one()
        |> Query.HotspotActivity.challenges_completed()

      assert challenges_completed == 1
    end
  end
end
