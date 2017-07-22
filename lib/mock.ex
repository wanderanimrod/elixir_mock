defmodule ElixirMock.Mock do
  @moduledoc """
  Contains functions that examine mocks and manipulate their state
  """

  @typedoc """
  Represents a mock.

  This is the type mock creation functions like `ElixirMock.mock_of/2` and `ElixirMock.defmock_of/2` return. In reality,
  these mocks are just modules with the same api as the modules they are based on. This type is here to help
  document which functions in _ElixirMock_ require mock modules as arguments.
  """
  @opaque mock :: module

  @doc """
  Gets values from context passed to mocks at definition time.

  An `ArgumentError` is thrown if the key doesn't exist in the mock's context. See the `ElixirMock.defmock_of/3`
  documentation for details on how to use this function.
  """
  @spec context(Map.key, ElixirMock.Mock.mock) :: term
  def context(key, mock) do
    mock.__elixir_mock__mock_context(key)
  end

  @doc """
  Lists all calls made to functions defined on the mock.

  Every time a function on a mock is called, the mock registers that call and keeps it for its whole lifespan. This
  function gets all these calls and returns them. Each function call is recorded as a tuple of the form
  `{:function_name, [arguments]}` and is added into a list of calls. Earlier calls will appear earlier in the list than
  those made later.

  Example:
  ```
  require ElixirMock
  import ElixirMock
  alias ElixirMock.Mock

  my_mock = mock_of Integer

  my_mock.to_string 1
  my_mock.digits 1234

  Mock.list_calls(my_mock) == [:to_string: [1], digits: [1234]]
  #=> true
  ```
  """
  @spec list_calls(ElixirMock.Mock.mock) :: list(tuple)
  def list_calls(mock) do
    mock.__elixir_mock__list_calls
  end

  @doc """
  Removes all registered calls from the mock.

  Every time a function on a mock is called, the mock registers that call and keeps it for its whole lifespan. This data
  is what assertion macros like `ElixirMock.assert_called/1` use. The `clear_calls/1` function removes all recorded calls
  from the mock, in effect taking it back into the state it was at definition time.

  Example:
    ```
    defmodule MyTest do
      use ExUnit.Case
      require ElixirMock
      import ElixirMock
      alias ElixirMock.Mock

      test "should clear mock calls" do
        my_mock = mock_of Integer

        my_mock.to_string(1)
        assert_called my_mock.to_string(1) # passes

        :ok = Mock.clear_calls(my_mock)
        assert_called my_mock.to_string(1) # fails!
      end
    end
    ```
  """
  @spec clear_calls(ElixirMock.Mock.mock) :: :ok
  def clear_calls(mock) do
    mock.__elixir_mock__reset
  end
end