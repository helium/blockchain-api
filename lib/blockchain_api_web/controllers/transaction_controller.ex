defmodule BlockchainAPIWeb.TransactionController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPI.{Util, Query, Schema}

  alias BlockchainAPIWeb.{
    PaymentView,
    GatewayView,
    LocationView,
    CoinbaseView,
    POCRequestView,
    POCReceiptsView,
    SecurityView,
    DataCreditView,
    ElectionView,
    RewardsView,
    OUIView,
    SecExchangeView
  }

  import BlockchainAPI.Cache.CacheService

  require Logger

  action_fallback BlockchainAPIWeb.FallbackController

  def index(conn, %{"block_height" => height} = _params) do
    txns = Query.Transaction.get(height)

    conn
    |> put_cache_headers(ttl: :long, key: "eternal")
    |> render("index.json", transactions: txns)
  end

  def show(conn, %{"hash" => hash}) do
    bin_hash = hash |> Util.string_to_bin()

    case Query.Transaction.type(bin_hash) do
      "payment" ->
        payment = Query.PaymentTransaction.get!(bin_hash)

        conn
        |> put_view(PaymentView)
        |> render("show.json", payment: payment)

      "gateway" ->
        gateway = Query.GatewayTransaction.get!(bin_hash)

        conn
        |> put_view(GatewayView)
        |> render("show.json", gateway: gateway)

      "coinbase" ->
        coinbase = Query.CoinbaseTransaction.get!(bin_hash)

        conn
        |> put_view(CoinbaseView)
        |> render("show.json", coinbase: coinbase)

      "security" ->
        security = Query.SecurityTransaction.get!(bin_hash)

        conn
        |> put_view(SecurityView)
        |> render("show.json", security: security)

      "data_credit" ->
        data_credit = Query.DataCreditTransaction.get!(bin_hash)

        conn
        |> put_view(DataCreditView)
        |> render("show.json", data_credit: data_credit)

      "election" ->
        election = Query.ElectionTransaction.get!(bin_hash)

        conn
        |> put_view(ElectionView)
        |> render("show.json", election: election)

      "location" ->
        location = Query.LocationTransaction.get!(bin_hash)

        conn
        |> put_view(LocationView)
        |> render("show.json", location: location)

      "poc_request" ->
        poc_request = Query.POCRequestTransaction.get!(bin_hash)

        conn
        |> put_view(POCRequestView)
        |> render("show.json", poc_request: poc_request)

      "poc_receipts" ->
        poc_receipts = Query.POCReceiptsTransaction.get(bin_hash)

        conn
        |> put_view(POCReceiptsView)
        |> render("show.json", poc_receipts: poc_receipts)

      "rewards" ->
        rewards = Query.RewardsTransaction.get!(bin_hash)

        conn
        |> put_view(RewardsView)
        |> render("show.json", rewards: rewards)

      "oui" ->
        oui = Query.OUITransaction.get!(bin_hash)

        conn
        |> put_view(OUIView)
        |> render("show.json", oui: oui)

      "security_exchange" ->
        sec_exchange = Query.SecurityExchangeTransaction.get!(bin_hash)

        conn
        |> put_view(SecExchangeView)
        |> render("show.json", sec_exchange: sec_exchange)

      _ ->
        :error
    end
  end

  def create(conn, %{"txn" => txn0}) do
    txn =
      txn0
      |> Base.decode64!()
      |> :blockchain_txn.deserialize()

    chain = :blockchain_worker.blockchain()
    ledger = :blockchain.ledger(chain)

    case :blockchain.height(chain) do
      {:error, _} ->
        send_resp(conn, 404, "no_chain")

      {:ok, height} ->
        # exec job flag is set to true by default
        create_pending_txn(conn, ledger, txn, height, true)
        send_resp(conn, 200, "ok")
    end
  end

  defp create_pending_txn(conn, ledger, txn, height, exec_job_flag) do
    case :blockchain_txn.type(txn) do
      :blockchain_txn_payment_v1 ->
        create_pending_payment(txn, height, exec_job_flag)

      :blockchain_txn_add_gateway_v1 ->
        create_pending_gateway(conn, ledger, txn, height, exec_job_flag)

      :blockchain_txn_assert_location_v1 ->
        create_pending_location(txn, height, exec_job_flag)

      :blockchain_txn_oui_v1 ->
        create_pending_oui(txn, height, exec_job_flag)

      :blockchain_txn_security_exchange_v1 ->
        create_pending_sec_exchange(txn, height, exec_job_flag)

      :blockchain_txn_bundle_v1 ->
        create_pending_bundle(conn, ledger, txn, height, exec_job_flag)

      _ ->
        :ok
    end
  end

  defp create_pending_gateway(conn, ledger, txn, height, false) do
    # Exec job flag is set to false, don't run the honeydew job
    # Check that the account exists in the DB
    owner = :blockchain_txn_add_gateway_v1.owner(txn)

    case Query.Account.get(owner) do
      nil ->
        # Create account
        {:ok, fee} = :blockchain_ledger_v1.transaction_fee(ledger)

        case Query.Account.create(%{balance: 0, address: owner, nonce: 0, fee: fee}) do
          {:ok, _} ->
            Schema.PendingGateway.map(txn, height)
            |> Map.put(:honeydew_submit_gateway_queue_lock, nil)
            |> Query.PendingGateway.create()

          {:error, _} ->
            send_resp(conn, 404, "error_adding_gateway_owner")
        end

      _account ->
        Schema.PendingGateway.map(txn, height) |> Query.PendingGateway.create()
    end
  end
  defp create_pending_gateway(conn, ledger, txn, height, true) do
    # Check that the account exists in the DB
    owner = :blockchain_txn_add_gateway_v1.owner(txn)

    case Query.Account.get(owner) do
      nil ->
        # Create account
        {:ok, fee} = :blockchain_ledger_v1.transaction_fee(ledger)

        case Query.Account.create(%{balance: 0, address: owner, nonce: 0, fee: fee}) do
          {:ok, _} ->
            Schema.PendingGateway.map(txn, height) |> Query.PendingGateway.create()

          {:error, _} ->
            send_resp(conn, 404, "error_adding_gateway_owner")
        end

      _account ->
        Schema.PendingGateway.map(txn, height) |> Query.PendingGateway.create()
    end
  end

  defp create_pending_payment(txn, height, false) do
    Schema.PendingPayment.map(txn, height)
    |> Map.put(:honeydew_submit_payment_queue_lock, nil)
    |> Query.PendingPayment.create()
  end
  defp create_pending_payment(txn, height, true) do
    Schema.PendingPayment.map(txn, height)
    |> Query.PendingPayment.create()
  end

  defp create_pending_location(txn, height, false) do
    Schema.PendingLocation.map(txn, height)
    |> Map.put(:honeydew_submit_location_queue_lock, nil)
    |> Query.PendingLocation.create()
  end
  defp create_pending_location(txn, height, true) do
    Schema.PendingLocation.map(txn, height)
    |> Query.PendingLocation.create()
  end

  defp create_pending_oui(txn, height, false) do
    Schema.PendingOUI.map(txn, height)
    |> Map.put(:honeydew_submit_oui_queue_lock, nil)
    |> Query.PendingOUI.create()
  end
  defp create_pending_oui(txn, height, true) do
    Schema.PendingOUI.map(txn, height)
    |> Query.PendingOUI.create()
  end

  defp create_pending_sec_exchange(txn, height, false) do
    Schema.PendingSecExchange.map(txn, height)
    |> Map.put(:honeydew_submit_sec_exchange_queue_lock, nil)
    |> Query.PendingSecExchange.create()
  end
  defp create_pending_sec_exchange(txn, height, true) do
    Schema.PendingSecExchange.map(txn, height)
    |> Query.PendingSecExchange.create()
  end

  defp create_pending_bundle(conn, ledger, txn, height, true) do
    # create pending bundle txn
    Schema.PendingBundle.map(txn, height)
    |> Query.PendingBundle.create()

    # create pending bundled txns
    :blockchain_txn_bundle_v1.txns(txn)
    |> Enum.each(
      fn t ->
        # don't trigger jobs for bundled txns
        create_pending_txn(conn, ledger, t, height, false)
      end)
  end

end
