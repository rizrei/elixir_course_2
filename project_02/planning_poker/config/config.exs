import Config

config :planning_poker,
  port: 4040,
  pool_size: 4

import_config "#{config_env()}.exs"
