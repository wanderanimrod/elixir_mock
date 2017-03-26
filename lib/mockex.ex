defmodule Mockex do
  @moduledoc """
  Documentation for Mockex.
  """

  require Logger

  defmacro defkv(real_functions) do
    quote bind_quoted: [real_functions: real_functions] do
      Enum.map real_functions, fn {fn_name, arity} ->
        args = case arity do
          0 -> []
          _ -> Enum.to_list(1..arity)
        end

        def unquote(:"#{fn_name}")(unquote_splicing(args)) do
          nil
        end
      end
    end
  end

  defmacro create_mock(real_module, mock_module_name) do
    quote do
      defmodule unquote(mock_module_name) do
        require Mockex

        real_functions = unquote(real_module).__info__(:functions)
        Mockex.defkv(real_functions)
      end
    end
  end

  defp random_module_name, do: :"#{UUID.uuid4(:hex)}"

  defp extract_stubs({:def, _, [{fn_name, _, _}, _]}) do
    [fn_name]
  end

#  defp extract_stubs([ast]) do
#    ast
#  end

  defmacro defmock(real_module, do: mock_ast) do
    stubs = extract_stubs(mock_ast)
    mod_name = random_module_name()

    quote do
      defmodule unquote(mod_name) do
        require Mockex

        unquote(mock_ast)

        real_functions = unquote(real_module).__info__(:functions)
        unstubbed_fns = Enum.filter real_functions, fn {fn_name, arity} ->
          not fn_name in unquote(stubs)
        end
        Mockex.defkv(unstubbed_fns)
      end
    end

  end

  def of(real_module) do
    mod_name = random_module_name()
    create_mock(real_module, mod_name)
    mod_name
  end

end