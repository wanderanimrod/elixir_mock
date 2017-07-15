defmodule ElixirMock.MatchersTest do
  use ExUnit.Case, async: true
  require ElixirMock

  import ElixirMock.Matchers
  import ElixirMock

  defmodule RealModule do
    def function_one(_), do: :real_result_one
    def function_two(_, _), do: :real_result_two
  end

  test "should test if function was called with integer arguments" do
    mock = mock_of RealModule

    mock.function_one(:not_an_int)
    refute_called mock.function_one(any(:integer))

    mock.function_one(1)
    assert_called mock.function_one(any(:integer))
  end

  test "should test function args with custom matcher" do
    a_person_over_30_years_old = {:matches, fn(%{age: age}) -> age > 30 end}

    mock = mock_of RealModule

    mock.function_one(%{age: 20})
    refute_called mock.function_one(a_person_over_30_years_old)

    mock.function_one(%{age: 40})
    assert_called mock.function_one(a_person_over_30_years_old)
  end

  test "should provide convenience 'any()' wrapper to match anything" do
    assert any() == {:matches, ElixirMock.Matchers.InBuilt.any(:_)}
  end

  test "should provide 'any(type)' wrapper to generate matcher statement for type" do
    assert any(:integer) == {:matches, ElixirMock.Matchers.InBuilt.any(:integer)}
  end

  test "should provide 'literal' wrapper to generate matcher statement for args that are matchers" do
    assert literal({:matches, 10}) == {:__elixir_mock__literal, {:matches, 10}}
  end

end