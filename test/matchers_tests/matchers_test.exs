defmodule Mockex.MatchersTest do
  use ExUnit.Case, async: true

  require Mockex
#  import Mockex

  defmodule RealModule do
    def function_one(_), do: :real_result_one
    def function_two(_, _), do: :real_result_two
  end

#  test "should test if function was called with int arguments" do
#    mock = mock_of RealModule
#
#    mock.function_one(:not_an_int)
#    refute_called mock.function_one(any(:int))
#
#    mock.function_one(1)
#    assert_called mock.function_one(any(:int))
#  end
end