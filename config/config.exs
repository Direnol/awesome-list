# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

# Configures the endpoint
config :awesome_list, AwesomeListWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "6B9YLlWEshCWWuumCk4MpKZweup53JmQ4AD3Ec7ECanSqANBIIlypqsfu/t4tFdt",
  render_errors: [view: AwesomeListWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: AwesomeList.PubSub,
  live_view: [signing_salt: "0KbFT95Y"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :awesome_list,
  user_agent: 'AwesomeList collector'

config :awesome_list, AwesomeList,
  # Указываем репозиторий
  repo: "h4cc/awesome-elixir",
  # Путь в репозитории до файла, где описаны проекты
  file: "./README.md",
  # Ветка
  branch: "master",
  user: System.get_env("GITHUB_USER", ""),
  token: System.get_env("GITHUB_TOKEN", "")

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
