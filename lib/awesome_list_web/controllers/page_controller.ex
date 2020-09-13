defmodule AwesomeListWeb.PageController do
  use AwesomeListWeb, :controller

  def index(%Plug.Conn{} = conn, params) do
    repos =
      AwesomeList.get_readme()
      |> AwesomeList.parse()

    {conn, repos} = case Map.get(params, "min_stars") do
      nil -> {conn, repos}
      min_stars ->
        case Integer.parse(min_stars) do
          {min, ""} ->
            {conn, Enum.map(repos, fn ({group_name, desc, repos}) ->
              {
                group_name,
                desc,
                Enum.filter(repos, (&do_filter_min_stars(&1, min)))
              }
            end)}
          _ ->
            {
              put_flash(conn, :error, "Cannot parse #{min_stars}"),
              repos
            }
        end

    end

    render(conn, "index.html", %{repos: repos})
  end


  defp do_filter_min_stars({_, _, _, %{stars: stars}}, min_stars) do
    stars >= min_stars
  end

  # Репозитории не из Github также будут исключены
  defp do_filter_min_stars(_, _min_stars) do
    false
  end
end
