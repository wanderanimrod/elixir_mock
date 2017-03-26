defmodule MockexTest do
  use ExUnit.Case, async: true
  alias Mockex, as: Mock

  defmodule RealModule do
    def function_one(_arg), do: :real_result_one
    def function_two(_arg1, _arg2), do: :real_result_two
  end

  test "module registration" do
    mock = Mock.of RealModule
    assert mock.function_one() == nil
#    assert mock.__info__(:functions) == [function_one: 1, function_two: 2]
  end

#  test "should create full mocks of module returning fake results" do
#    mock = Mock.of RealModule
#    assert mock.functions() == []
##    assert mock.function_one(1) == nil
#  end

#  test "should allow for inspection of calls on mock" do
#    m = mock RealModule
#    m.function_one(1)
#    assert called m.function_one(1)
#  end

#  test "should allow partial stubbing of methods" do
#
#  end

end
