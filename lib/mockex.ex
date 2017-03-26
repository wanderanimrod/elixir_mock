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
          _ -> 1..arity |> Enum.map(&(Macro.var(:"arg_#{&1}", __MODULE__)))
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

  defp build_fn_spec(fn_name, args) do
    arity = case args do
      nil -> 0
      list -> length(list)
    end
    {fn_name, arity}
  end

  defp extract_stubs({:def, _, [{fn_name, _, args}, _]}) do
    [build_fn_spec(fn_name, args)]
  end

  defp extract_stubs({:__block__, _, content_ast}) do
    content_ast
    |> Enum.filter(fn({member_type, _, _}) -> member_type == :def end)
    |> Enum.map(fn({:def, _, [{fn_name, _, args}, _]}) ->
      build_fn_spec(fn_name, args)
    end)
  end

  defmacro defmock_of(real_module, do: mock_ast) do
    stubs = extract_stubs(mock_ast)
    mod_name = random_module_name()
    quote do
      defmodule unquote(mod_name) do
        require Mockex

        unquote(mock_ast)

        real_functions = unquote(real_module).__info__(:functions)
        unstubbed_fns = Enum.filter real_functions, fn {fn_name, arity} ->
          not {fn_name, arity} in unquote(stubs)
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