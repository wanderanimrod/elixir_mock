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
    with_mock(mock) = defmock_of RealModule do
      def function_one(_), do: :overriden_f1
    end

    assert mock.function_one(1) == :overriden_f1
    assert mock.function_two(1, 2) == nil
  end

  test "should allow more than one function declaration in mock definition" do
    with_mock(mock) = defmock_of RealModule do
      def function_one(_), do: :overriden_f1
      def function_two(_, _), do: :overriden_f2
    end

    assert mock.function_one(1) == :overriden_f1
    assert mock.function_two(1, 2) == :overriden_f2
  end

  test "should only override function heads with the same arity as the heads specified for the mock" do
    defmodule Real do
      def x, do: {:arity, 0}
      def x(_arg), do: {:arity, 1}
    end

    with_mock(mock) = defmock_of Real do
      def x, do: :overriden_x
    end

    assert mock.x == :overriden_x
    assert mock.x(:some_arg) == nil
  end

  test "should tell if a stubbed method was called on mock" do
    with_mock(mock) = defmock_of RealModule do
      def function_one(_), do: :overriden_f1
    end

    mock.function_one(:arg)

    assert called mock, function_one(:arg)
  end

# todo test that stubbed method was not called.

# todo
"""
  Improve the verification api. Perhaps use Module.eval_quoted in the `called` macro?
  - The api we want is: `assert called mock.function_one(:arg)`
"""

# todo genserver behaviour of real module is kept in mock (stubbing genserver calls to return nil instead of state will cause the mock to blow up)
# todo how does it affect multiple function heads with pattern matching?
# todo how does it affect functions with guard clauses
# todo allow retention of original function behaviour for unstubbed functions
# todo don't allow function definitions that are not on the real module
# todo simplify mock matching with 'with_mock(mock) = Mock.defmock Real do ... end'

end
