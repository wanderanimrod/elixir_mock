defmodule Mockex.Matchers do

  def any, do: {Mockex.Matchers.Any, :_}

  def any(type), do: {Mockex.Matchers.Any, type}

  @doc false
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
end