defmodule Mockex.Matcher do
  @callback matches?(args :: nonempty_list) :: boolean

  def is_a_matcher(module) do
    try do
      function_exported? module, :matches?, 1
    rescue
      ArgumentError -> false
    end
  end
end