defmodule MockWatcherTest.MatcherTest do
  use ExUnit.Case, async: true

  setup do
    mock_name = :"#{UUID.uuid4(:hex)}"
    {:ok, _} = MockWatcher.start_link(mock_name)

    watcher_name = MockWatcher.get_watcher_name_for(mock_name)
    {:ok, %{watcher: watcher_name}}
  end

  test "should find calls with args for which matcher returns true for corresponding arg", %{watcher: watcher} do
    defmodule Anything do
      @behaviour Mockex.Matcher
      def matches?(_), do: true
    end

    :ok = GenServer.call(watcher, {:record_call, :fn_name, [1, 2]})
    {was_called, _calls} = GenServer.call(watcher, {:call_exists, :fn_name, [Anything, 2]})

    assert was_called
  end

  test "should fail to find calls with args for which matcher returns false", %{watcher: watcher} do
    defmodule FalseMatcher do
      @behaviour Mockex.Matcher
      def matches?(_), do: false
    end

    :ok = GenServer.call(watcher, {:record_call, :fn_name, [1, 2]})
    {was_called, _calls} = GenServer.call(watcher, {:call_exists, :fn_name, [FalseMatcher, 2]})

    refute was_called
  end
end