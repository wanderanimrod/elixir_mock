defmodule MockexTest.CallVerification do
  use ExUnit.Case, async: true

  require Logger
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

  # todo assert that watcher process dies with the test process (using spawn? or Task.async & Task.await)
  @tag skip: "watcher processes are not dying after parent dies despite being started with start_link"
  test "mock watcher should die with the test process" do
    test_fn = fn ->
      mock = mock_of RealModule
      watcher_pid = MockWatcher.get_watcher_name_for(mock) |> Process.whereis()
      assert Process.alive? watcher_pid
      watcher_pid
    end

    test_task = Task.async(test_fn)
    watcher_pid = Task.await(test_task)

    Logger.debug "
    test_proc = #{inspect self()}
    watcher_proc = #{inspect watcher_pid}
    task_details = #{inspect test_task}"

    refute Process.alive? test_task.pid
    refute Process.alive? watcher_pid
  end
end
