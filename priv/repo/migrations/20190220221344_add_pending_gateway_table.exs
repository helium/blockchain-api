defmodule BlockchainAPI.Repo.Migrations.AddPendingGatewayTable do
  use Ecto.Migration

  def change do
    create table(:pending_gateways) do
      add :hash, :binary, null: false
      add :status, :string, null: false, default: "pending"
      add :gateway, :binary, null: false
      add :fee, :bigint, null: false, default: 0
      add :amount, :bigint, null: false, default: 0

      add :owner, references(:accounts, on_delete: :nothing, column: :address, type: :binary), null: false

      timestamps()
    end

    create unique_index(:pending_gateways, [:owner, :hash, :status], name: :unique_pending_gateway)
  end
end
