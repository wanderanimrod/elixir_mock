defmodule Mockex.Matchers.AnyTest do
  use ExUnit.Case, async: true
  import Mockex.Matchers.Any

  test "should test if arg is an integer" do
    assert matches?(:integer, 10)
    refute matches?(:integer, 12.6)
  end

  test "should test if arg is a float" do
    assert matches?(:float, 10.1)
    refute matches?(:float, 12)
  end

  test "should test if arg is a list" do
    assert matches?(:list, [])
    refute matches?(:list, 12)
  end

  test "should test if arg is a pid" do
    assert matches?(:pid, self())
    refute matches?(:pid, :not_a_pid)
  end

  test "should test if arg is a atom" do
    assert matches?(:atom, :my_atom)
    refute matches?(:atom, 12)
  end

  test "should test if arg is a binary" do
    assert matches?(:binary, "string")
    refute matches?(:binary, [])
  end

  test "should test if arg is a function" do
    assert matches?(:function, &Integer.is_even?/1)
    refute matches?(:function, "not a function")
  end

  test "should test if arg is a boolean" do
    assert matches?(:boolean, false)
    refute matches?(:boolean, 12)
  end

  test "should test if arg is a number" do
    assert matches?(:number, 10.1)
    assert matches?(:number, 10)
    refute matches?(:number, [])
  end

  test "should test if arg is a map" do
    assert matches?(:map, %{})
    refute matches?(:map, {})
  end

  test "should test if arg is a tuple" do
    assert matches?(:tuple, {})
    refute matches?(:tuple, %{})
  end

  test "should test if arg matches anything" do
    things = [[], {}, :atom, 10, 2.3, self(), %{}, "string"]
    Enum.each things, fn thing ->
      assert matches?(:_, thing)
    end
  end

  test "should raise error if called with unsupported type" do
    expected_message = "Type :unknown_type is not supported by this matcher"
    assert_raise ArgumentError, expected_message, fn ->
      matches?(:unknown_type, 10)
    end
  end

end