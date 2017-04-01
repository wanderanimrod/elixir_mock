defmodule Mockex.MatchersTest do
  use ExUnit.Case, async: true
  require Mockex

  import Mockex.Matchers
  import Mockex

  defmodule RealModule do
    def function_one(_), do: :real_result_one
    def function_two(_, _), do: :real_result_two
  end

  test "should provide convenience 'any()' wrapper to match anything" do
    assert any() == {Mockex.Matchers.Any, :_}
  end

  test "should provide 'any(type)' wrapper to generate matcher statement for type" do
    assert any(:int) == {Mockex.Matchers.Any, :int}
  end

  test "should test if function was called with integer arguments" do
    mock = mock_of RealModule

    mock.function_one(:not_an_int)
    refute_called mock.function_one(any(:integer))

    mock.function_one(1)
    assert_called mock.function_one(any(:integer))
  end
end