defmodule Mockex.Matchers do

  # todo require tests to explicitly import this module instead of getting matchers with the Mockex main module.
  defmacro __using__(_) do
    quote do
      def any(type) do
        {Any, [type]}
      end
    end
  end

  def find_call({expected_fn, expected_args}, calls) do
    calls
    |> Enum.filter(fn {called_fn, _} -> called_fn == expected_fn end)
    |> Enum.any?(fn {_fn_name, args} -> match_call_args(expected_args, args) end)
  end

  defp match_call_args(expected_args, actual_args) when(length(actual_args) != length(expected_args)), do: false

  defp match_call_args(expected_args, actual_args) do
    Enum.zip(expected_args, actual_args)
    |> Enum.all?(fn {expected, actual} ->
      case expected do
        {:__mockex__literal, literal_module} -> literal_module == actual
        {potential_matcher, matcher_spec} -> _match_args({potential_matcher, matcher_spec}, actual)
        potential_specless_matcher -> _match_args(potential_specless_matcher, actual)
      end
    end)
  end

  defp _match_args({potential_matcher, matcher_spec} = expected_tuple, actual) do
    if Mockex.Matcher.is_a_matcher(potential_matcher)
      do potential_matcher.matches?(matcher_spec, actual)
      else expected_tuple == actual end
  end

  defp _match_args(potential_matcher, actual) do
    if Mockex.Matcher.is_a_matcher(potential_matcher)
      do potential_matcher.matches?([], actual)
      else potential_matcher == actual
    end
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