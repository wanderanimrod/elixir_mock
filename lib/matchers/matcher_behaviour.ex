defmodule Mockex.Matcher do
  @callback matches?(matcher_spec :: nonempty_list, arg_to_match :: any) :: boolean

  def is_a_matcher(module) do
    try do
      function_exported? module, :matches?, 2
    rescue
      ArgumentError -> false
    end
  end
end