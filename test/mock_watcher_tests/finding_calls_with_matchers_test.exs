defmodule MockWatcherTest.FindingCallsWithMatchers do
  use ExUnit.Case, async: true

  setup do
    mock_name = :"#{UUID.uuid4(:hex)}"
    {:ok, _} = MockWatcher.start_link(mock_name)

    watcher_name = MockWatcher.get_watcher_name_for(mock_name)
    {:ok, %{watcher: watcher_name}}
  end

  test "should find calls with args for which matcher for corresponding arg returns true", %{watcher: watcher} do
    anything = {:matches, fn _ -> true end}

    :ok = GenServer.call(watcher, {:record_call, :fn_name, [1, 2]})
    {was_called, _calls} = GenServer.call(watcher, {:call_exists, :fn_name, [anything, 2]})

    assert was_called
  end

  test "should fail to find calls with args for which matcher function returns false", %{watcher: watcher} do
    nothing = {:matches, fn _ -> false end}

    :ok = GenServer.call(watcher, {:record_call, :fn_name, [1, 2]})
    {was_called, _calls} = GenServer.call(watcher, {:call_exists, :fn_name, [nothing, 2]})

    refute was_called
  end

  test "should allow for special {:matches, matcher} tuple to be matched literally", %{watcher: watcher} do
    literal_argument = {:matches, 10}
    :ok = GenServer.call(watcher, {:record_call, :fn_name, [literal_argument]})
    {was_called, _calls} = GenServer.call(watcher, {:call_exists, :fn_name, [{:__mockex__literal, literal_argument}]})
    assert was_called
  end

  @tag :this
  test "should work with matcher that takes arguments in its spec", %{watcher: watcher} do
    any = fn(type) ->
      case type do
        :integer -> &is_integer/1
        :boolean -> &is_boolean/1
      end
    end

    :ok = GenServer.call(watcher, {:record_call, :fn_name, [1, false]})
    {was_called, _calls} = GenServer.call(watcher, {:call_exists, :fn_name, [{:matches, any.(:integer)}, {:matches, any.(:boolean)}]})

    assert was_called
  end

end