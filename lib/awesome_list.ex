defmodule AwesomeList do
  @moduledoc """
  AwesomeList keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  @app :awesome_list

  @spec format_description(String.t()) :: String.t()
  @doc """
    Убираем лидирующие тире и пробелы
  """
  def format_description(desc) do
    case desc
         |> String.trim_leading() do
      "-" <> desc -> desc |> String.trim_leading()
      desc -> desc
    end
  end

  @spec get_readme() :: String.t()
  @doc """
    Получаем README в формате `makrdown`. В котором описаны репозитории
    в формате

      ```markdown

          ...

        ## Group Name

        *Short Description of group*

        * [repo-name1](url1) - Description1
        * [repo-name2](url2) - Description2
      ```
  """
  def get_readme() do
    config = Application.get_env(@app, __MODULE__)
    repo = Keyword.get(config, :repo)
    branch = Keyword.get(config, :branch)
    file = Keyword.get(config, :file)

    ConCache.get_or_store(__MODULE__, {repo, branch, file}, fn ->
      do_get_readme_http(repo, branch, file)
    end)
  end

  @spec do_get_readme_http(String.t(), String.t(), Path.t()) :: String.t()
  defp do_get_readme_http(repo, branch, file) do
    case URI.merge("https://raw.githubusercontent.com/#{repo}/#{branch}/", file)
         |> to_string()
         |> to_charlist()
         |> :httpc.request() do
      {:ok, {{_, 200, _}, _headers, body}} -> body |> to_string()
      {:ok, resp} -> {:error, resp}
      err -> err
    end
  end

  @spec get_repo_info(String.t()) :: map() | {:error, term()}
  @doc """
    Используя Github API возвращаем информацию о репозитории
  """
  def get_repo_info(repo) do
    get_repo_info(
      repo,
      Application.get_env(@app, __MODULE__)[:user],
      Application.get_env(@app, __MODULE__)[:token]
    )
  end

  @spec get_repo_commit(String.t()) :: list() | {:error, term()}
  @doc """
    Получаем информацию о коммитах
  """
  def get_repo_commit(repo) do
    get_repo_info(
      Path.join(repo, "commits"),
      Application.get_env(@app, __MODULE__)[:user],
      Application.get_env(@app, __MODULE__)[:token]
    )
  end

  @spec get_repo_info(String.t(), String.t(), String.t(), String.t()) ::
          list() | map() | {:error, term()}
  @doc """
    Используя Github API возвращаем информацию о репозитории, дополнительно
    авторизуясь, чтобы увеличить лимит для использования.
  """
  def get_repo_info(repo, user, token, api \\ "https://api.github.com/repos/")

  def get_repo_info("/" <> repo, user, token, api) do
    get_repo_info(repo, user, token, api)
  end

  def get_repo_info(repo, user, token, api) do
    ConCache.get_or_store(__MODULE__, {repo, user, token, api}, fn ->
      do_get_repo_info(repo, user, token, api)
    end)
  end

  @spec do_get_repo_info(String.t(), String.t(), String.t(), String.t()) ::
          map() | list() | {:error, term()}
  defp do_get_repo_info(repo, user, token, api) do
    auth =
      if user != nil and token != nil do
        [
          {'Authorization',
           'Basic ' ++
             (:base64.encode(to_charlist(user) ++ ':' ++ to_charlist(token)) |> to_charlist)}
        ]
      else
        []
      end

    case URI.merge(api, repo)
         |> to_string
         |> to_charlist
         |> (&:httpc.request(
               :get,
               {&1, auth ++ [{'User-Agent', Application.get_env(@app, :user_agent, 'Awesome')}]},
               [],
               []
             )).() do
      {:ok, {{_, 200, _}, _headers, body}} -> body |> Jason.decode!()
      {:ok, resp} -> {:error, resp}
      err -> err
    end
  end

  @spec parse(String.t()) :: [{group_name, description(), [repo_info()]}]
        when group_name: String.t()
  @doc """
    Обрабатываем содержимое README, пропуская вводную, и преобразуем группы
    репозиториев в список, дополняя репозиторий из Github доп информацией
  """
  def parse(readme_text) do
    ConCache.get_or_store(__MODULE__, :crypto.hash(:sha, readme_text), fn ->
      do_parse(to_string(readme_text)) |> Enum.reverse()
    end)
  end

  @typep repo_info :: {repo, href, description, info}
  @typep description :: String.t()
  @typep repo :: String.t()
  @typep href :: String.t()
  @typep info :: map()

  @spec do_parse(String.t()) :: [{group_name, description(), [repo_info()]}]
        when group_name: String.t()
  def do_parse(readme_text) do
    case readme_text |> EarmarkParser.as_ast() do
      {:ok, ast, _} -> Enum.reduce(ast, {[], :init}, &do_parse_tag/2) |> elem(0)
      err -> err
    end
  end

  @spec do_parse_tag(tuple(), {list(repo_info()), state}) :: {list(repo_info()), state}
        when state: atom()
  defp do_parse_tag({"h2", _, [name], _}, {acc, _}) do
    {[name | acc], :desc}
  end

  defp do_parse_tag({"p", _, [{_, _, desc, _}], _}, {[name | acc], :desc}) do
    {[{name, Earmark.Transform.transform(desc)} | acc], :process}
  end

  defp do_parse_tag({"ul", _, repos, _}, {[{group_name, desc} | other_repos], :process}) do
    # repos
    # |> Enum.map(&collect_repos/1)
    formated_repos =
      repos
      |> Enum.map(&Task.async(fn -> collect_repos(&1) end))
      |> Enum.map(&Task.await/1)

    {[{group_name, desc, formated_repos} | other_repos], :init}
  end

  defp do_parse_tag({_, _, _, _}, {_, _} = acc) do
    acc
  end

  @spec collect_repos(tuple()) :: repo_info()
  defp collect_repos({"li", _, [{"p", _, [{"a", [{"href", href}], [name], _} | desc], _}], _}),
    do: do_collect_repos(href, name, Earmark.Transform.transform(desc))

  defp collect_repos(
         {"li", _,
          [
            {"a", [{"href", href}], [name], _}
            | desc
          ], %{}}
       ),
       do: do_collect_repos(href, name, Earmark.Transform.transform(desc))

  @spec do_collect_repos(String.t(), String.t(), String.t()) :: repo_info()
  defp do_collect_repos(href, name, desc) do
    uri = URI.parse(href)

    case uri.host do
      "github.com" ->
        {name, href, desc,
         %{
           stars:
             case get_repo_info(uri.path) do
               {:error, _} ->
                 -1

               data ->
                 data |> Map.get("stargazers_count")
             end,
           last_commit:
             case get_repo_commit(uri.path) do
               {:error, _} ->
                 nil

               data ->
                 data
                 |> hd
                 |> Map.get("commit")
                 |> Map.get("author")
                 |> Map.get("date")
             end
         }}

      _ ->
        {name, href, desc, %{}}
    end
  end
end
