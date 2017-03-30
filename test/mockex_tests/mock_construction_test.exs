defmodule MockexTest.Construction do
  use ExUnit.Case, async: true

  require Mockex
  import Mockex

  defmodule RealModule do
    def function_one(_arg), do: :real_result_one
    def function_two(_arg1, _arg2), do: :real_result_two
  end

  test "should create full mock of module with functions returning nil" do
    mock = mock_of RealModule
    assert mock.function_one(1) == nil
    assert mock.function_two(1, 2) == nil
  end

  test "should leave mocked module intact" do
    mock = mock_of RealModule
    assert mock.function_one(1) == nil
    assert RealModule.function_one(1) == :real_result_one
  end

  @tag :this
  test "should allow functions on mock to delegate to real module functions when they return :call_through" do
    with_mock(mock) = defmock_of RealModule do
      def function_one(_), do: :call_through
    end
    assert mock.function_one(1) == RealModule.function_one(1)
    assert mock.function_two(1, 2) == nil
  end
#
#  test "should allow creation of mock with all functions calling the real module" do
#    mock = mock_of RealModule, :call_through_all
#    assert mock.function_one(1) == RealModule.function_one(1)
#    assert mock.function_two(1, 2) == RealModule.function_two(1, 2)
#  end
  
#  test "should allow creation of mock with all unspecified functions calling through" do
#    with_mock(mock) = defmock_of RealModule do
#      @keep_undeclared_functions true
#      def function_one(_), do: :overridden_f1
#    end
#    assert mock.function_one(1) == :overridden_f1
#    assert mock.function_two(1, 2) == RealModule.function_two(1, 2)
#  end
#
#  test "should stub all functions if @keep_undeclared_functions is false" do
#    with_mock(mock) = defmock_of RealModule do
#      @keep_undeclared_functions false # the default
#      def function_one(_), do: :overridden_f1
#    end
#    assert mock.function_one(1) == :overridden_f1
#    assert mock.function_two(1, 2) == nil
#  end

  test "should allow definition of mock partially overriding real module functions" do
    with_mock(mock) = defmock_of RealModule do
      def function_one(_), do: :overridden_f1
    end

    assert mock.function_one(1) == :overridden_f1
    assert mock.function_two(1, 2) == nil
  end

  test "should allow more than one function declaration in mock definition" do
    with_mock(mock) = defmock_of RealModule do
      def function_one(_), do: :overridden_f1
      def function_two(_, _), do: :overridden_f2
    end

    assert mock.function_one(1) == :overridden_f1
    assert mock.function_two(1, 2) == :overridden_f2
  end

  test "should only override function heads with the same arity as the heads specified for the mock" do
    defmodule Real do
      def x, do: {:arity, 0}
      def x(_arg), do: {:arity, 1}
    end

    with_mock(mock) = defmock_of Real do
      def x, do: :overridden_x
    end

    assert mock.x == :overridden_x
    assert mock.x(:some_arg) == nil
  end

  test "should create default nil-mock when mock body is empty" do
    normal_nil_mock = mock_of RealModule
    with_mock(empty_body_mock) = defmock_of RealModule do end
    assert normal_nil_mock.function_one(10) == empty_body_mock.function_one(10)
    assert normal_nil_mock.function_two(10, 20) == empty_body_mock.function_two(10, 20)
  end

# todo how does it affect multiple function heads with pattern matching?
# todo how does it affect functions with guard clauses
# todo don't allow function definitions that are not on the real module
# todo allow retention of original function behaviour for unstubbed functions | just call @real_module.fn_name(unquote_splicing(args)? or a postwalk
# todo add some matchers any(type)
"""
  todo:
  Improve the verification api. Perhaps use Module.eval_quoted in the `called` macro?
  - The api we want is: `assert_called mock.function_one(:arg)`
"""
end
