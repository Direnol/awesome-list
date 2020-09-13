defmodule AwesomeListTest do
  use ExUnit.Case, async: false

  describe "test getter functions" do
    test "&Awesome.get_readme/0" do
      readme = AwesomeList.get_readme()
      assert is_binary(readme)
      assert 0 != String.length(readme)
      assert match?({:ok, _, _}, EarmarkParser.as_ast(readme))
    end

    test "&Awesome.get_repo_info/0" do
      repo_info = AwesomeList.get_repo_info("Direnol/awesome-list")
      assert match?(%{}, repo_info)
      assert Map.has_key?(repo_info, "stargazers_count")

      assert match?({:error, _}, AwesomeList.get_repo_info("direnol/awesomee-list"))
    end

    test "&Awesome.get_repo_commit/0" do
      repo_info = AwesomeList.get_repo_commit("Direnol/awesome-list")
      assert is_list(repo_info)

      assert match?({:error, _}, AwesomeList.get_repo_commit("direnol/awesomee-list"))
    end


  end
end
