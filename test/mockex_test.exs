defmodule MockexTest do
  use ExUnit.Case, async: true
  alias Mockex, as: Mock

  defmodule RealModule do
    def function_one(_arg), do: :real_result_one
    def function_two(_arg1, _arg2), do: :real_result_two
  end

  test "module registration" do
    mock_mod = Mock.of(RealModule)
    assert mock_mod.f == 10
  end

#  test "should create full mocks of module returning fake results" do
#    m = Mockex.mock RealModule
#    assert m.function_one(1) == :fake
#    assert :random_module_name.function_one(1) == 0
#    assert m == []
#    assert m.function_two(1, 2) == :fake
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
