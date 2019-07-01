defmodule BlockchainAPI.Query.RewardsTransaction do
  @moduledoc false
  import Ecto.Query, warn: false

  alias BlockchainAPI.{Repo, Schema.RewardsTransaction}

  def create(attrs \\ %{}) do
    %RewardsTransaction{}
    |> RewardsTransaction.changeset(attrs)
    |> Repo.insert()
  end
end
