defmodule Mockex.MatchersTest do
  use ExUnit.Case, async: true
  require Mockex

  import Mockex.Matchers
  import Mockex

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
    defmodule APersonOver30YearsOld do
      @behaviour Mockex.Matcher
      def matches?(_, %{age: age}), do: age > 30
    end

    mock = mock_of RealModule

    mock.function_one(%{age: 20})
    refute_called mock.function_one(APersonOver30YearsOld)

    mock.function_one(%{age: 40})
    assert_called mock.function_one(APersonOver30YearsOld)
  end

  test "should provide convenience 'any()' wrapper to match anything" do
    assert any() == {Mockex.Matchers.Any, :_}
  end

  test "should provide 'any(type)' wrapper to generate matcher statement for type" do
    assert any(:int) == {Mockex.Matchers.Any, :int}
  end

  test "should provide 'literal' wrapper to generate matcher statement for args that are matchers" do
    assert literal(Mockex.Matchers.Any) == {:__mockex__literal, Mockex.Matchers.Any}
  end

end