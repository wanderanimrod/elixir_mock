defmodule MockexTest do
  use ExUnit.Case, async: true
  require Mockex
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
    {_, mock, _, _} = Mock.defmock RealModule do
      def function_one(_), do: :overriden_f1
    end
    assert mock.function_one(1) == :overriden_f1
#    assert mock.function_two()
  end

# todo don't allow function definitions that are not on the real module
# todo allow multiple mocks from same module with different functions defined
# todo genserver behaviour of real module is kept in mock
# todo calls to mock can be inspected
# todo how does it affect multiple function heads with pattern matching?
# todo how does it affect functions with guard clauses
# todo allow partial stubbing and retention of orignal module behaviour

end
