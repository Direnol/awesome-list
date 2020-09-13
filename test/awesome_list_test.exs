defmodule AwesomeListTest do
  use ExUnit.Case, async: false

  describe "test getter functions" do
    describe "&Awesome.get_readme/0" do
      readme = AwesomeList.get_readme()
      assert is_binary(readme)
      assert 0 != length(readme)
      assert match?({:ok, _, _}, EarmarkParser.as_ast(readme))
    end
  end
end
