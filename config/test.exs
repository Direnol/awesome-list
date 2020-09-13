use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :awesome_list, AwesomeListWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

config :awesome_list, AwesomeList,
  # Указываем репозиторий
  repo: "Direnol/awesome-list",
  # Путь в репозитории до файла, где описаны проекты
  file: "./test/README.md",
  # Ветка
  branch: "master",
  user: System.get_env("GITHUB_USER", ""),
  token: System.get_env("GITHUB_TOKEN", "")
