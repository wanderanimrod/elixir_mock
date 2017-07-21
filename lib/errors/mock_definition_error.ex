defmodule ElixirMock.MockDefinitionError do
  @moduledoc "Error raised when `ElixirMock.defmock_of/2` and `ElixirMock.defmock_of/3` are given an illegal mock definition"

  defexception message: "bad mock definition"

  @doc false
  def raise_it(invalid_stubs, real_module) when is_list(invalid_stubs) do
    bad_stubs_string = format_invalid_stubs(invalid_stubs)
    message = "Cannot stub functions [#{bad_stubs_string}] because they are not defined on #{inspect real_module}"
    raise ElixirMock.MockDefinitionError, message: message
  end

  defp format_invalid_stubs(stubs) do
    stubs
    |> Enum.map(fn {fn_name, arity} -> "&#{fn_name}/#{arity}" end)
    |> Enum.join(", ")
  end
end