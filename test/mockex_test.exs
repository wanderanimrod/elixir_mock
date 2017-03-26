defmodule MockexTest do
  use ExUnit.Case, async: true
  require Mockex
  import Mockex
  alias Mockex, as: Mock

  defmodule RealModule do
    def function_one(_arg), do: :real_result_one
    def function_two(_arg1, _arg2), do: :real_result_two
  end

  test "should create full mock of module with functions returning nil" do
    mock = Mock.of RealModule
    assert mock.function_one(1) == nil
    assert mock.function_two(1, 2) == nil
  end

  test "should leave mocked module intact" do
    mock = Mock.of RealModule
    assert mock.function_one(1) == nil
    assert RealModule.function_one(1) == :real_result_one
  end

  test "should allow definition of mock partially overriding real module functions" do
    {_, mock, _, _} = defmockof RealModule do
      def function_one(_), do: :overriden_f1
    end

    assert mock.function_one(1) == :overriden_f1
    assert mock.function_two(1, 2) == nil
  end

#  test "should only override function heads with the same arity as the heads specified for the mock" do
#    defmodule Real do
#      def x, do: {:arity, 0}
#      def x(_arg), do: {:arity, 1}
#    end
#
#    {_, mock, _, _} = Mock.defmock Real do
#      def x, do: 10
#    end
#
#    assert mock.function_one(1) == :overriden_f1
#    assert mock.function_two(1, 2) == nil
#  end

# todo don't allow function definitions that are not on the real module
# todo allow multiple mocks from same module with different functions defined
# todo genserver behaviour of real module is kept in mock
# todo calls to mock can be inspected
# todo how does it affect multiple function heads with pattern matching?
# todo how does it affect functions with guard clauses
# todo allow partial stubbing and retention of orignal module behaviour
# todo simplify mock matching with 'with_mock(mock) = Mock.defmock Real do ... end'

end
