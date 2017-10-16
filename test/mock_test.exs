defmodule MockTest do
  use ExUnit.Case, async: true

  require ElixirMock
  import ElixirMock
  alias ElixirMock.Mock

  test "should reset mock get mock context" do
    with_mock(mock) = defmock_of List, %{fixed_answer: 10} do
      def first(_), do: Mock.context(:fixed_answer, __MODULE__)
    end
    assert mock.first([]) == 10
  end

  test "should allow nil values in mock context" do
    with_mock(mock) = defmock_of List, %{fixed_answer: nil} do
      def first(_), do: Mock.context(:fixed_answer, __MODULE__)
    end
    assert mock.first([]) == nil
  end

  test "should list mock calls" do
    mock = mock_of List
    mock.first([1, 3])
    assert Mock.list_calls(mock) == [{:first, [[1, 3]]}]
  end

  test "should clear mock calls" do
    mock = mock_of List
    mock.first([])
    assert length(Mock.list_calls(mock)) == 1

    Mock.clear_calls(mock)

    assert Mock.list_calls(mock) == []
  end
end