defmodule MockWatcherTest do
  use ExUnit.Case, async: true

  setup do
    mock_name = :"#{UUID.uuid4(:hex)}"
    watcher_name = MockWatcher.get_watcher_name_for(mock_name)
    {:ok, %{mock: mock_name, watcher: watcher_name}}
  end

  test "should start process with given mock name", %{mock: mock} do
    {:ok, _} = MockWatcher.start_link(mock)
    assert is_pid(Process.whereis(:"__mockex__watcher_#{mock}"))
  end

  test "should verify that call does not exist when there are no calls on watcher", %{mock: mock, watcher: watcher} do
    {:ok, _} = MockWatcher.start_link(mock)
    assert GenServer.call(watcher, {:call_exists, :fn_name, [:arg]}) == {false, []}
  end

  test "should record and verify that call with correct args exists", %{mock: mock, watcher: watcher} do
    {:ok, _} = MockWatcher.start_link(mock)
    :ok = GenServer.call(watcher, {:record_call, :fn_name, [1, 2]})
    assert GenServer.call(watcher, {:call_exists, :fn_name, [1, 2]}) == {true, [{:fn_name, [1, 2]}]}
  end

  test "should record and verify that call with wrong args does not exist", %{mock: mock, watcher: watcher} do
    {:ok, _} = MockWatcher.start_link(mock)
    :ok = GenServer.call(watcher, {:record_call, :fn_name, [1, 2]})
    assert GenServer.call(watcher, {:call_exists, :fn_name, [:other_args]}) == {false, [{:fn_name, [1, 2]}]}
  end

  test "should record and verify that wrong func call with correct args does not exist",
  %{mock: mock, watcher: watcher} do
    {:ok, _} = MockWatcher.start_link(mock)
    :ok = GenServer.call(watcher, {:record_call, :fn_name, [:arg]})
    assert GenServer.call(watcher, {:call_exists, :other_fn, [:arg]}) == {false, [{:fn_name, [:arg]}]}
  end

  test "should clear calls", %{mock: mock, watcher: watcher} do
    {:ok, _} = MockWatcher.start_link(mock)
    :ok = GenServer.call(watcher, {:record_call, :fn_name, [:arg]})
    :ok = GenServer.call(watcher, :clear_calls)
    assert GenServer.call(watcher, {:call_exists, :fn_name, [:arg]}) == {false, []}
  end
end