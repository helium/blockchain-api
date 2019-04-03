defmodule BlockchainAPI.Schema.PendingGateway do
  use Ecto.Schema
  import Ecto.Changeset
  alias BlockchainAPI.{Util, Schema.PendingGateway}
  @fields [:id, :hash, :status, :owner, :gateway, :fee, :amount]

  @derive {Phoenix.Param, key: :hash}
  @derive {Jason.Encoder, only: @fields}
  schema "pending_gateways" do
    field :hash, :binary, null: false
    field :status, :string, null: false, default: "pending"
    field :gateway, :binary, null: false
    field :owner, :binary, null: false
    field :fee, :integer, null: false, default: 0
    field :amount, :integer, null: false, default: 0

    timestamps()
  end

  @doc false
  def changeset(pending_gateway, attrs) do
    pending_gateway
    |> cast(attrs, [:hash, :status, :gateway, :owner, :fee, :amount])
    |> validate_required([:hash, :status, :gateway, :owner, :fee, :amount])
    |> foreign_key_constraint(:owner)
    |> unique_constraint(:unique_pending_gateway, name: :unique_pending_gateway)
  end

  def encode_model(pending_gateway) do
    pending_gateway
    |> Map.take(@fields)
    |> Map.merge(%{
      owner: Util.bin_to_string(pending_gateway.owner),
      gateway: Util.bin_to_string(pending_gateway.gateway),
      hash: Util.bin_to_string(pending_gateway.hash),
      type: "gateway"
    })
  end

  defimpl Jason.Encoder, for: PendingGateway do
    def encode(pending_gateway, opts) do
      pending_gateway
      |> PendingGateway.encode_model()
      |> Jason.Encode.map(opts)
    end
  end
end
