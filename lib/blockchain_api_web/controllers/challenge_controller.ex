defmodule BlockchainAPIWeb.ChallengeController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPI.Query

  action_fallback BlockchainAPIWeb.FallbackController

  def index(conn, params) do
    challenges = Query.POCReceiptsTransaction.list(params)
    ongoing = Query.POCRequestTransaction.ongoing(params)
    {successful, failed} = Query.POCReceiptsTransaction.aggregate_challenges(challenges)
    issued = Query.POCReceiptsTransaction.issued()

    render(conn,
      "index.json",
      challenges: challenges,
      total_ongoing: ongoing,
      issued: issued,
      successful: successful,
      failed: failed
    )
  end

  def show(conn, %{"id" => id}) do
    challenge = Query.POCReceiptsTransaction.show(id)
    render(conn, "show.json", challenge: challenge)
  end

end
