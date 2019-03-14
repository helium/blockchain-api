defmodule BlockchainAPI.TxnManager do

  use GenServer
  alias BlockchainAPI.{Query, Util}
  require Logger
  @me __MODULE__

  #==================================================================
  # API
  #==================================================================
  def start_link(args) do
    GenServer.start_link(@me, args, name: @me)
  end

  def submit(txn) do
    GenServer.call(@me, {:submit, txn})
  end

  #==================================================================
  # Callbacks
  #==================================================================
  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call({:submit, txn}, _from, state) do
    try do
      pending_txn = get_pending_transaction(txn)

      case pending_txn.status do
        "done" ->
          {:reply, :done, state}
        "error" ->
          {:reply, :error, state}
        "pending" ->
          {:reply, :pending, state}
      end
    rescue
      _error in Ecto.NoResultsError ->
        :ok = submit_txn(txn)
        {:reply, :submitted, state}
    end
  end

  #==================================================================
  # Helper Functions
  #==================================================================
  defp submit_txn(txn0) do
    txn = txn0 |> deserialize()
    submit_txn(:blockchain_txn.type(txn), txn)
  end

  defp submit_txn(:blockchain_txn_payment_v1, txn) do
    {:ok, pending_txn} = Query.PendingPayment.create(pending_payment_map(txn))
    :ok = :blockchain_worker.submit_txn(
      txn,
      fn(res) ->
        case res do
          :ok ->
            pending_txn.hash
            |> Query.PendingPayment.get!()
            |> Query.PendingPayment.update!(%{status: "done"})
          {:error, _reason} ->
            Logger.error("Failed to submit payment: #{Util.bin_to_string(pending_txn.hash)}")
            pending_txn.hash
            |> Query.PendingPayment.get!()
            |> Query.PendingPayment.update!(%{status: "error"})
        end
      end)
  end
  defp submit_txn(:blockchain_txn_add_gateway_v1, txn) do
    {:ok, pending_txn} = Query.PendingGateway.create(pending_gateway_map(txn))
    :ok = :blockchain_worker.submit_txn(
      txn,
      fn(res) ->
        case res do
          :ok ->
            pending_txn.hash
            |> Query.PendingGateway.get!()
            |> Query.PendingGateway.update!(%{status: "done"})
          {:error, _reason} ->
            Logger.error("Failed to submit gateway: #{Util.bin_to_string(pending_txn.hash)}")
            pending_txn.hash
            |> Query.PendingGateway.get!()
            |> Query.PendingGateway.update!(%{status: "error"})
        end
      end)
  end
  defp submit_txn(:blockchain_txn_assert_location_v1, txn) do
    {:ok, pending_txn} = Query.PendingLocation.create(pending_location_map(txn))
    :ok = :blockchain_worker.submit_txn(
      txn,
      fn(res) ->
        case res do
          :ok ->
            pending_txn.hash
            |> Query.PendingLocation.get!()
            |> Query.PendingLocation.update!(%{status: "done"})
          {:error, _reason} ->
            Logger.error("Failed to submit location: #{Util.bin_to_string(pending_txn.hash)}")
            pending_txn.hash
            |> Query.PendingLocation.get!()
            |> Query.PendingLocation.update!(%{status: "error"})
        end
      end)
  end

  def deserialize(txn) do
    txn |> Base.decode64! |> :blockchain_txn.deserialize()
  end

  defp pending_payment_map(txn) do
    %{
      hash: :blockchain_txn_payment_v1.hash(txn),
      amount: :blockchain_txn_payment_v1.amount(txn),
      fee: :blockchain_txn_payment_v1.fee(txn),
      nonce: :blockchain_txn_payment_v1.nonce(txn),
      payer: :blockchain_txn_payment_v1.payer(txn),
      payee: :blockchain_txn_payment_v1.payee(txn)
    }
  end

  defp pending_gateway_map(txn) do
    %{
      hash: :blockchain_txn_add_gateway_v1.hash(txn),
      owner: :blockchain_txn_add_gateway_v1.owner(txn),
      fee: :blockchain_txn_add_gateway_v1.fee(txn),
      amount: :blockchain_txn_add_gateway_v1.amount(txn),
      gateway: :blockchain_txn_add_gateway_v1.gateway(txn)
    }
  end

  defp pending_location_map(txn) do
    %{
      hash: :blockchain_txn_assert_location_v1.hash(txn),
      nonce: :blockchain_txn_assert_location_v1.nonce(txn),
      fee: :blockchain_txn_assert_location_v1.fee(txn),
      owner: :blockchain_txn_assert_location_v1.owner(txn),
      location: to_string(:h3.to_string(:blockchain_txn_assert_location_v1.location(txn))),
      gateway: :blockchain_txn_assert_location_v1.gateway(txn)
    }
  end

  defp get_pending_transaction(txn0) do
    txn = txn0 |> deserialize()
    get_pending_transaction(:blockchain_txn.type(txn), :blockchain_txn.hash(txn))
  end

  defp get_pending_transaction(:blockchain_txn_payment_v1, hash) do
    Query.PendingPayment.get!(hash)
  end
  defp get_pending_transaction(:blockchain_txn_add_gateway_v1, hash) do
    Query.PendingGateway.get!(hash)
  end
  defp get_pending_transaction(:blockchain_txn_assert_location_v1, hash) do
    Query.PendingLocation.get!(hash)
  end
end
