defmodule BlockchainAPI.Query.POCWitness do
  @moduledoc false
  import Ecto.Query, warn: false

  alias BlockchainAPI.{Repo, Schema.POCWitness}

  def list(_) do
    POCWitness
    |> Repo.all()
  end

  def create(attrs \\ %{}) do
    %POCWitness{}
    |> POCWitness.changeset(attrs)
    |> Repo.insert()
  end
end
