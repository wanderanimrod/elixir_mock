defmodule Mockex do
  @moduledoc """
  Documentation for Mockex.
  """

  require Logger

  defmacro inject_empty_stubs(real_functions) do
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

  defmacro defmock_of(real_module, do: mock_ast) do
    mock_name = random_module_name()

    quote do
      {:ok, _pid} = MockWatcher.start_link(unquote(mock_name))

      defmodule unquote(mock_name) do
        require Mockex

        unquote(inject_call_recording_into(mock_ast))

        unquote(unstubbed_fns_ast(real_module, mock_ast))

        def __mockex__call_exists(fn_name, args) do
          watcher_proc = MockWatcher.get_watcher_name_for(__MODULE__)
          GenServer.call(watcher_proc, {:call_exists, fn_name, args})
        end
      end
    end
  end

  defmacro called(mock_module, call) do
    {fn_name, _, args} = call
    quote do
      unquote(mock_module).__mockex__call_exists(unquote(fn_name), unquote(args))
    end
  end

  defmacro with_mock(mock_var_name) do
    quote do
      {_, unquote(mock_var_name), _, _}
    end
  end

  defmacro create_mock(real_module, mock_module_name) do
    quote do
      defmodule unquote(mock_module_name) do
        require Mockex

        real_functions = unquote(real_module).__info__(:functions)
        Mockex.inject_empty_stubs(real_functions)
      end
    end
  end

  def of(real_module) do
    mod_name = random_module_name()
    create_mock(real_module, mod_name)
    mod_name
  end

  defp unstubbed_fns_ast(real_module, mock_ast) do
    stubs = extract_stubs(mock_ast)
    quote do
      real_functions = unquote(real_module).__info__(:functions)
      unstubbed_fns = Enum.filter real_functions, fn {fn_name, arity} ->
        not {fn_name, arity} in unquote(stubs)
      end
      Mockex.inject_empty_stubs(unstubbed_fns)
    end
  end

  defp random_module_name, do: :"#{UUID.uuid4(:hex)}"

  defp random_arg_name, do: :"mockex_unignored__#{UUID.uuid4(:hex)}"

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

  defp cleanup_ignored_args(nil), do: nil

  defp cleanup_ignored_args(args) do
    Enum.map args, fn
      {:_, context, nil} -> {random_arg_name(), context, nil}
      used_argument -> used_argument
    end
  end

  defp fn_call_recording_ast(fn_name, args) do
    quote do
      watcher_proc = MockWatcher.get_watcher_name_for(__MODULE__)
      GenServer.call(watcher_proc, {:record_call, unquote(fn_name), unquote(args)})
    end
  end

  defp inject_call_recording_lines(lines, fn_name, args) when is_list(lines) do
    {:__block__, [], storage_call_lines} = fn_call_recording_ast(fn_name, args)
    [do: {:__block__, [], storage_call_lines ++ lines}]
  end

  defp inject_call_recording_into({:def, _, [{fn_name, _, args}, _]} = mock_ast) do
    clean_args = cleanup_ignored_args(args)
    Macro.postwalk(mock_ast, fn
      [do: plain_value]            -> inject_call_recording_lines([plain_value], fn_name, clean_args)
      [do: {:__block__, _, lines}] -> inject_call_recording_lines(lines, fn_name, clean_args)
      {^fn_name, context, _}        -> {fn_name, context, clean_args}
      anything_else -> anything_else
    end)
  end

  defp inject_call_recording_into({:__block__, _, _} = block) do
    Macro.postwalk block, fn
      {:def, _, _, _} = fn_ast -> inject_call_recording_into(fn_ast)
      anything_else            -> anything_else
    end
  end

end