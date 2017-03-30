defmodule Mockex.MockDefinitionError do
  defexception message: "bad mock definition"

  def raise_it(invalid_stubs, real_module) when is_list(invalid_stubs) do
    bad_stubs_string = format_invalid_stubs(invalid_stubs)
    message = "Cannot stub functions [#{bad_stubs_string}] because they are not defined on #{inspect real_module}"
    raise Mockex.MockDefinitionError, message: message
  end

  defp format_invalid_stubs(stubs) do
    stubs
    |> Enum.map(fn {fn_name, arity} -> "&#{fn_name}/#{arity}" end)
    |> Enum.join(", ")
  end
end