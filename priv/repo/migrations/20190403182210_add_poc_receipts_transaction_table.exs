defmodule BlockchainAPI.Repo.Migrations.AddPocReceiptsTransactionTable do
  use Ecto.Migration

  def change do
    create table(:poc_receipts_transactions) do
      add :signature, :binary, null: false
      add :fee, :bigint, null: false
      add :onion, :binary, null: false
      add :challenger_loc, :string, null: false

      add :hash, references(:transactions, on_delete: :nothing, column: :hash, type: :binary), null: false
      add :challenger, references(:gateway_transactions, on_delete: :nothing, column: :gateway, type: :binary), null: false

      timestamps()
    end

    create unique_index(:poc_receipts_transactions, [:hash])

  end
end
