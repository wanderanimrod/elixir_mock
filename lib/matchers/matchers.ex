defmodule ElixirMock.Matchers do

  def any, do: {:matches, ElixirMock.Matchers.InBuilt.any(:_)}

  def any(type), do: {:matches, ElixirMock.Matchers.InBuilt.any(type)}

  def literal(value), do: {:__elixir_mock__literal, value}

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
        {:__elixir_mock__literal, explicit_literal} -> explicit_literal == actual
        {:matches, matcher} -> _match_args(matcher, actual)
        implicit_literal -> implicit_literal == actual
      end
    end)
  end

  defp _match_args(matcher, actual) when is_function(matcher) do
    matcher_arity = :erlang.fun_info(matcher)[:arity]
    error_message = "Use of bad function matcher '#{inspect matcher}' in match expression.
    Argument matchers must be functions with arity 1. This function has arity #{matcher_arity}"
    if  matcher_arity != 1 do
      raise ArgumentError, message: error_message
    end
    matcher.(actual)
  end

  defp _match_args(_, non_function_matcher) do
    error_message = "Use of non-function matcher '#{inspect non_function_matcher}' in match expression.
    Argument matchers must be in the form {:matches, &matcher_function/1}. If you expected your stubbed function to have
    been called with literal {:matches, #{inspect non_function_matcher}}, use ElixirMock.Matchers.literal({:matches, #{inspect non_function_matcher}})"
    raise ArgumentError, message: error_message
  end
end