defmodule Mockex.Matchers do

  defmacro __using__(_) do
    quote do
      def any(type) do
        {Any, [type]}
      end
    end
  end

  def find_call({expected_fn, expected_args}, calls) do
    found_call_by_fn_name = calls |> Enum.find(fn {called_fn, _} -> called_fn == expected_fn end)
    case found_call_by_fn_name do
      nil -> false
      {_fn_name, args} -> match_call_args(args, expected_args)
    end
  end

  defp match_call_args(actual_args, expected_args) when(length(actual_args) != length(expected_args)), do: false

  defp match_call_args(actual_args, expected_args) do
    Enum.zip(expected_args, actual_args)
    |> Enum.all?(fn {expected, actual} ->
      if Mockex.Matcher.is_a_matcher(expected)
        do expected.matches?(actual)
        else expected == actual
      end
    end)
  end


  # todo
  @moduledoc """
    - If a module is passed as a func call verification arg, if that module implements the MockexMatcher behaviour,
    we treat it as a matcher. Otherwise, we test if a call exists with the literal module as an arg.
    - If you want to test that a function was called with a matcher as an arg, use
        `assert_called mock.func(literal(MyMatcher))`

    # todo any(:type)
    is_atom/1         is_binary/1       is_bitstring/1    is_boolean/1
    is_float/1        is_function/1     is_function/2     is_integer/1
    is_list/1         is_map/1          is_nil/1          is_number/1
    is_pid/1          is_port/1         is_reference/1    is_tuple/1
    any

    # todo any(MyStructModule)? can you check if a map is of type 'MyStruct'?
      # todo custom matchers
  """

end