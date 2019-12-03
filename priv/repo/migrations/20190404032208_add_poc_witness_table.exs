defmodule BlockchainAPI.Repo.Migrations.AddPocWitnessTable do
  use Ecto.Migration

  def change do
    create table(:poc_witnesses) do
      add :poc_path_elements_id, references(:poc_path_elements, on_delete: :delete_all, column: :id, type: :bigint), null: false
      add :gateway, :binary, null: false
      add :timestamp, :bigint, null: false
      add :signal, :integer, null: false
      add :packet_hash, :binary, null: false
      add :signature, :binary, null: false
      add :location, :string, null: false
      add :owner, :binary, null: false

      timestamps()
    end
  end

end
