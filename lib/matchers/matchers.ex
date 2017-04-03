defmodule Mockex.Matchers do

  def any, do: {:matches, Mockex.Matchers.InBuilt.any(:_)}

  def any(type), do: {:matches, Mockex.Matchers.InBuilt.any(type)}

  def literal(value), do: {:__mockex__literal, value}

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
        {:__mockex__literal, literal} -> literal == actual
        {:matches, matcher} -> _match_args(matcher, actual)
        implicit_literal -> implicit_literal == actual
      end
    end)
  end

  defp _match_args(matcher, actual) when is_function(matcher) do
    matcher.(actual)
  end

  defp _match_args(_, _non_function_matcher) do
    # todo tell user to use literal helper.
  end
end