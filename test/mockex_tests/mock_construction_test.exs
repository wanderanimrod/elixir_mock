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

  test "should allow functions on mock to delegate to real module functions when they return :call_through" do
    with_mock(mock) = defmock_of RealModule do
      def function_one(_), do: :call_through
    end
    assert mock.function_one(1) == RealModule.function_one(1)
    assert mock.function_two(1, 2) == nil
  end

  test "should allow calling through more than one function" do
    with_mock(mock) = defmock_of RealModule do
      def function_one(_), do: :call_through
      def function_two(_, _), do: :call_through
    end
    assert mock.function_one(1) == RealModule.function_one(1)
    assert mock.function_two(1, 2) == RealModule.function_two(1, 2)
  end

  test "should allow creation of mock with all functions calling the real module" do
    mock = mock_of RealModule, :call_through
    assert mock.function_one(1) == RealModule.function_one(1)
    assert mock.function_two(1, 2) == RealModule.function_two(1, 2)
  end
  
  test "should allow creation of mock with all unspecified functions calling through" do
    with_mock(mock) = defmock_of RealModule do
      @call_through_undeclared_functions true
      def function_one(_), do: :overridden_f1
    end
    assert mock.function_one(1) == :overridden_f1
    assert mock.function_two(1, 2) == RealModule.function_two(1, 2)
  end

  test "should stub all functions if @call_through_undeclared_functions is false" do
    with_mock(mock) = defmock_of RealModule do
      @call_through_undeclared_functions false # the default
      def function_one(_), do: :overridden_f1
    end
    assert mock.function_one(1) == :overridden_f1
    assert mock.function_two(1, 2) == nil
  end

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

  test "should not allow functions on mock that are not in the real module" do
    # todo add "did you mean to stub function_one/1" if similar functions are present.
    expected_message = "Cannot stub functions [&missing_one/0, &missing_two/1] because they are not defined on MockexTest.Construction.RealModule"
    assert_raise Mockex.MockDefinitionError, expected_message, fn ->
      defmock_of RealModule do
        def missing_one, do: nil
        def missing_two(_), do: nil
      end
    end
  end

  @tag :this
  test "should allow private functions in mock definitions" do
    with_mock(mock) = defmock_of RealModule do
      def function_one(_) do
        private_function()
      end

      defp private_function, do: :response_from_private_function
    end

    assert mock.function_one(:blah) == :response_from_private_function
  end

  # todo add :debug option to mock definition that pretty prints the mock code.
  
end
