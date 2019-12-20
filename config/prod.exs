use Mix.Config

# For production, don't forget to configure the url host
# to something meaningful, Phoenix uses this information
# when generating URLs.
#
# Note we also include the path to a cache manifest
# containing the digested version of static files. This
# manifest is generated by the `mix phx.digest` task,
# which you should run after static files are built and
# before starting your production server.
port = String.to_integer(System.get_env("PORT") || "4001")
ro_mode = String.to_integer(System.get_env("RO_MODE") || "1")

config :blockchain_api, BlockchainAPIWeb.Endpoint,
  http: [port: port],
  url: [host: System.get_env("HOSTNAME") || "localhost", port: port],
  server: true,
  root: ".",
  version: Application.spec(:blockchain_api, :vsn),
  check_origin: false,
  # force_ssl: [hsts: true, rewrite_on: [:x_forwarded_proto]],
  secret_key_base: System.get_env("SECRET_KEY_BASE")

# cache_static_manifest: "priv/static/cache_manifest.json"

config :blockchain_api,
  env: Mix.env(),
  google_maps_secret: System.get_env("GOOGLE_MAPS_API_KEY"),
  onesignal_rest_api_key: System.get_env("ONESIGNAL_API_KEY"),
  onesignal_app_id: System.get_env("ONESIGNAL_APP_ID"),
  fastly_api_key: System.get_env("FASTLY_API_KEY"),
  fastly_service_id: System.get_env("FASTLY_SERVICE_ID"),
  notifier_client: BlockchainAPI.NotifierClient,
  ro_mode: ro_mode

# Configure your database
config :blockchain_api, BlockchainAPI.Repo,
  username: System.get_env("DATABASE_USER"),
  password: System.get_env("DATABASE_PASS"),
  database: System.get_env("DATABASE_NAME"),
  hostname: System.get_env("DATABASE_HOST"),
  pool_size: 20,
  timeout: 600_000,
  queue_target: 120_000,
  queue_interval: 5_000,
  log: false

config :blockchain,
  base_dir: String.to_charlist("/var/data/blockchain-api/prod/")

config :appsignal, :config, active: true
