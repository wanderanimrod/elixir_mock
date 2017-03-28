defmodule MockexTest.CallVerification do
  use ExUnit.Case, async: true

  require Mockex
  import Mockex

  defmodule RealModule do
    def function_one(_arg), do: :real_result_one
    def function_two(_arg1, _arg2), do: :real_result_two
  end

  test "should tell if a stubbed function was called on mock" do
    with_mock(mock) = defmock_of RealModule do
      def function_one(_) do
        :overriden_f1
      end
    end

    mock.function_one(:arg)

    assert_called mock, function_one(:arg)
  end

  test "should verify implicitly stubbed functions too" do
    mock = mock_of RealModule
    mock.function_one(1)
    assert_called mock, function_one(1)
    refute_called mock, function_two(1, 2)
  end

  test "should only successfully verify function call with exact arguments" do
    mock = mock_of RealModule
    mock.function_one(:arg)
    refute_called mock, function_one(:other_arg)
  end

  test "should verify that explicitly stubbed function was not called" do
    with_mock(mock) = defmock_of RealModule do
      def function_one(_), do: 10
    end
    refute_called mock, function_one(10)
  end

  test "should create default nil-mock when mock body is empty" do
    normal_nil_mock = mock_of RealModule
    with_mock(empty_body_mock) = defmock_of RealModule do end
    assert normal_nil_mock.function_one(10) == empty_body_mock.function_one(10)
    assert normal_nil_mock.function_two(10, 20) == empty_body_mock.function_two(10, 20)
  end

end
