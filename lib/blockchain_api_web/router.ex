defmodule BlockchainAPIWeb.Router do
  use BlockchainAPIWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", BlockchainAPIWeb do
    pipe_through :api

    resources "/blocks", BlockController, only: [:show, :index], param: "height" do
      resources "/transactions", TransactionController, only: [:index], param: "hash"
    end

    resources "/accounts", AccountController, only: [:index, :show], param: "address" do
      resources "/transactions", AccountTransactionController,
        only: [:index],
        param: "account_address"

      resources "/gateways", AccountGatewayController, only: [:index], param: "account_address"
    end

    # This has to be before the resources
    get "/hotspots/search", HotspotController, :search

    resources "/hotspots", HotspotController, only: [:index, :show], param: "address" do
      resources "/activity", ActivityController, only: [:index]
      resources "/rewards", HotspotRewardController, only: [:index]
      get "/receipts", HotspotController, :receipts
      get "/witnesses", HotspotController, :witnesses
      get "/stats", HotspotController, :stats, as: :hotspot_stats
    end

    resources "/transactions", TransactionController,
      only: [:index, :show, :create],
      param: "hash"

    resources "/gateways", GatewayController, only: [:index, :show], param: "hash"
    resources "/coinbase_transactions", CoinbaseController, only: [:index, :show], param: "hash"
    resources "/payment_transactions", PaymentController, only: [:index, :show], param: "hash"
    resources "/gateway_transactions", GatewayController, only: [:index, :show], param: "hash"
    resources "/location_transactions", LocationController, only: [:index, :show], param: "hash"
    resources "/challenges", ChallengeController, only: [:index, :show], param: "id"
    resources "/elections", ElectionTransactionController, only: [:index, :show], param: "hash"

    get "/pending_gateways", PendingGatewayController, :show
    get "/pending_locations", PendingLocationController, :show
    get "/pending_payments", PendingPaymentController, :show

    get "/stats", StatsController, :show
  end

  scope "/", BlockchainAPIWeb do
    get "/", HealthCheckController, :index
    get "/*path", FourOhFourController, :index
  end
end
