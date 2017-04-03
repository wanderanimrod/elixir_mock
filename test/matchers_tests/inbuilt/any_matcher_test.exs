defmodule Mockex.Matchers.AnyTest do
  use ExUnit.Case, async: true
  import Mockex.Matchers.InBuilt

  test "should test if arg is an integer" do
    assert any(:integer).(10)
    refute any(:integer).(12.6)
  end

  test "should test if arg is a float" do
    assert any(:float).(10.1)
    refute any(:float).(12)
  end

  test "should test if arg is a list" do
    assert any(:list).([])
    refute any(:list).(12)
  end

  test "should test if arg is a pid" do
    assert any(:pid).(self())
    refute any(:pid).(:not_a_pid)
  end

  test "should test if arg is a atom" do
    assert any(:atom).(:my_atom)
    refute any(:atom).(12)
  end

  test "should test if arg is a binary" do
    assert any(:binary).("string")
    refute any(:binary).([])
  end

  test "should test if arg is a function" do
    assert any(:function).(&Integer.is_even?/1)
    refute any(:function).("not a function")
  end

  test "should test if arg is a boolean" do
    assert any(:boolean).(false)
    refute any(:boolean).(12)
  end

  test "should test if arg is a number" do
    assert any(:number).(10.1)
    assert any(:number).(10)
    refute any(:number).([])
  end

  test "should test if arg is a map" do
    assert any(:map).(%{})
    refute any(:map).({})
  end

  test "should test if arg is a tuple" do
    assert any(:tuple).({})
    refute any(:tuple).(%{})
  end

  test "should test if arg matches anything" do
    things = [[], {}, :atom, 10, 2.3, self(), %{}, "string"]
    Enum.each things, fn thing ->
      assert any(:_).(thing)
    end
  end

  test "should raise error if called with unsupported type" do
    expected_message = "Type :unknown_type is not supported by this matcher"
    assert_raise ArgumentError, expected_message, fn ->
      any(:unknown_type).(10)
    end
  end

end