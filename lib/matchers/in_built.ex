defmodule ElixirMock.Matchers.InBuilt do
  @moduledoc false

  def any(type) do
    case type do
      :_ -> fn _thing -> true end
      :atom -> &is_atom/1
      :binary -> &is_bitstring/1
      :boolean -> &is_boolean/1
      :float -> &is_float/1
      :function -> &is_function/1
      :integer -> &is_integer/1
      :list -> &is_list/1
      :map -> &is_map/1
      :number -> &is_number/1
      :pid -> &is_pid/1
      :tuple -> &is_tuple/1
      %{__struct__: struct_type} -> &(is_map(&1) && Map.has_key?(&1, :__struct__) && &1.__struct__ == struct_type)
      unknown_type -> raise ArgumentError, message: "Type #{inspect unknown_type} is not supported by this matcher"
    end
  end
end