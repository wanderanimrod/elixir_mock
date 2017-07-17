defmodule ElixirMockTest.Messaging do
  use ExUnit.Case, async: true

  require ElixirMock
  import ElixirMock

  defmodule RealModule do
    def function_one(_arg), do: :real_result_one
    def function_two(_arg1, _arg2), do: :real_result_two
  end

  test "should provide info about calls when call is not found among existing calls" do
    mock = mock_of RealModule
    expected_message = "\n\nExpected function_one(:arg) to have been called but it was not found among calls:\n            * function_one(:some_arg)\n      * function_two(:some_arg, :other_arg)\n"

    mock.function_one(:some_arg)
    mock.function_two(:some_arg, :other_arg)

    assert_raise ExUnit.AssertionError, expected_message, fn ->
      assert_called mock.function_one(:arg)
    end
  end

  test "should provide user friendly message when unexpected call is found" do
    mock = mock_of RealModule
    expected_message = "\n\nDid not expect function_one(1) to be called but it was.\n"

    mock.function_one(1)

    assert_raise ExUnit.AssertionError, expected_message, fn ->
      refute_called mock.function_one(1)
    end
  end

  test "should provide user friendly message when expected call is not found on mock without calls" do
    mock = mock_of RealModule
    expected_message = "\n\nExpected function_one(:arg) to have been called but it was not found among calls:\n            * []\n"

    assert_raise ExUnit.AssertionError, expected_message, fn ->
      assert_called mock.function_one(:arg)
    end
  end
end
