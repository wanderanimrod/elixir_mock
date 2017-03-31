defmodule MockWatcherTest.MatcherTest do
  use ExUnit.Case, async: true

  defmodule EmptyModule do end # here so we don't get redefinition compiler warnings

  setup do
    mock_name = :"#{UUID.uuid4(:hex)}"
    {:ok, _} = MockWatcher.start_link(mock_name)

    watcher_name = MockWatcher.get_watcher_name_for(mock_name)
    {:ok, %{watcher: watcher_name}}
  end

  test "should find calls with args for which matcher returns true for corresponding arg", %{watcher: watcher} do
    defmodule Anything do
      @behaviour Mockex.Matcher
      def matches?(_, _), do: true
    end

    :ok = GenServer.call(watcher, {:record_call, :fn_name, [1, 2]})
    {was_called, _calls} = GenServer.call(watcher, {:call_exists, :fn_name, [Anything, 2]})

    assert was_called
  end

  test "should fail to find calls with args for which matcher returns false", %{watcher: watcher} do
    defmodule FalseMatcher do
      @behaviour Mockex.Matcher
      def matches?(_, _), do: false
    end

    :ok = GenServer.call(watcher, {:record_call, :fn_name, [1, 2]})
    {was_called, _calls} = GenServer.call(watcher, {:call_exists, :fn_name, [FalseMatcher, 2]})

    refute was_called
  end

  test "should work with matcher that takes arguments in its spec", %{watcher: watcher} do
    defmodule Any do
      @behaviour Mockex.Matcher
      def matches?(type, arg) do
        case type do
          :int -> is_integer(arg)
          :boolean -> is_boolean(arg)
        end
      end
    end

    :ok = GenServer.call(watcher, {:record_call, :fn_name, [1, false]})
    {was_called, _calls} = GenServer.call(watcher, {:call_exists, :fn_name, [{Any, :int}, {Any, :boolean}]})

    assert was_called
  end

  test "should match literal module args", %{watcher: watcher} do
    :ok = GenServer.call(watcher, {:record_call, :fn_name, [EmptyModule]})
    {was_called, _calls} = GenServer.call(watcher, {:call_exists, :fn_name, [EmptyModule]})

    assert was_called
  end

  @tag :this
  test "should match literal tuples", %{watcher: watcher} do
    :ok = GenServer.call(watcher, {:record_call, :fn_name, [{EmptyModule, 10}]})
    :ok = GenServer.call(watcher, {:record_call, :fn_name, [{:simple, :tuple}]})

    {was_called_with_module_tuple, _calls} = GenServer.call(watcher, {:call_exists, :fn_name, [{EmptyModule, 10}]})
    {was_called_with_simple_tuple, _calls} = GenServer.call(watcher, {:call_exists, :fn_name, [{:simple, :tuple}]})

    assert was_called_with_module_tuple
    assert was_called_with_simple_tuple
  end

  test "should match modules that implement all functions of the Mockex.Matcher behaviour but are not Matchers" do

  end
end