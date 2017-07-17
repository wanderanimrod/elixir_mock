defmodule ElixirMock do
  @moduledoc """

  """
  # TODO: This module has too many public functions and macros that should really be private

  require Logger

  @doc false
  defmacro inject_monitored_real_functions(real_module, real_functions) do
    quote bind_quoted: [real_module: real_module, real_functions: real_functions] do
      Enum.map real_functions, fn {fn_name, arity, call_through} ->
        args = case arity do
          0 -> []
          _ -> 1..arity |> Enum.map(&(Macro.var(:"arg_#{&1}", __MODULE__)))
        end

        def unquote(:"#{fn_name}")(unquote_splicing(args)) do
          watcher_proc = MockWatcher.get_watcher_name_for(__MODULE__)
          GenServer.call(watcher_proc, {:record_call, unquote(fn_name), unquote(args)})
          if unquote(call_through) do
            unquote(real_module).unquote(fn_name)(unquote_splicing(args))
          else
            nil
          end

        end
      end
    end
  end

  defmacro defmock_of(real_module, do: nil) do
    mock_name = random_module_name()
    quote do
      ElixirMock.create_mock(unquote(real_module), unquote(mock_name))
    end
  end

  defmacro defmock_of(real_module, context \\ {:%{}, [], []}, do: mock_ast) do
    call_through_unstubbed_fns = should_call_through_unstubbed_functions(mock_ast)
    mock_name = random_module_name()
    mock_fns = extract_mock_fns(mock_ast)
    stubs = Enum.map mock_fns, fn {_fn_type, {name, arity}} -> {name, arity} end

    quote do
     verify_mock_structure(unquote(mock_fns), unquote(real_module))
     {:ok, _pid} = MockWatcher.start_link(unquote(mock_name))

     defmodule unquote(mock_name) do
       require ElixirMock

       unquote(mock_ast |> inject_elixir_mock_function_utilities |> apply_stub_call_throughs(real_module))

       unquote(unstubbed_fns_ast(real_module, stubs, call_through_unstubbed_fns))

       ElixirMock.inject_elixir_mock_utilities(unquote(context))
     end
    end
  end

  @doc false
  defmacro create_mock(real_module, mock_module_name, call_through \\ false) do
    quote do
      {:ok, _pid} = MockWatcher.start_link(unquote(mock_module_name))

      defmodule unquote(mock_module_name) do
        require ElixirMock

        real_functions =
          unquote(real_module).__info__(:functions)
          |> Enum.map(fn {fn_name, arity} -> {fn_name, arity, unquote(call_through)} end)

        ElixirMock.inject_monitored_real_functions(unquote(real_module), real_functions)

        ElixirMock.inject_elixir_mock_utilities(%{})
      end
    end
  end

  def mock_of(real_module, call_through \\ false)

  def mock_of(real_module, :call_through),
    do: mock_of(real_module, true)

  def mock_of(real_module, call_through) do
    mod_name = random_module_name()
    create_mock(real_module, mod_name, call_through)
    mod_name
  end

  @doc false
  def build_call_string(fn_name, args) do
    args_string = args |> Enum.map(&(inspect &1)) |> Enum.join(", ")
    "#{fn_name}(#{args_string})"
  end

  @doc false
  def build_calls_string([]), do: "#{inspect []}"

  @doc false
  def build_calls_string(calls) do
    calls
    |> Enum.map(fn {func, args_list} -> build_call_string(func, args_list) end)
    |> Enum.join("\n * ")
  end

  @doc false
  defmacro inject_elixir_mock_utilities(context) do
    quote do
      @watcher_proc MockWatcher.get_watcher_name_for(__MODULE__)
      @mock_context unquote(context)

      def __elixir_mock__call_exists(fn_name, args) do
        GenServer.call(@watcher_proc, {:call_exists, fn_name, args})
      end

      def reset do
        :ok = GenServer.call(@watcher_proc, :clear_calls)
      end

      def list_calls,
        do: GenServer.call(@watcher_proc, :list_calls)

      def mock_context(key) when is_atom(key) do
        value = Map.get(@mock_context, key)
        if value, do: value, else: (raise ArgumentError, "#{inspect key} not found in mock context #{inspect @mock_context}")
      end
    end
  end

  defmacro refute_called({{:., _, [mock_ast, fn_name]}, _, args}) do
    quote bind_quoted: [mock_ast: mock_ast, fn_name: fn_name, args: args] do
      {mock_module, _} = Code.eval_quoted(mock_ast)

      {called, _existing_calls} = mock_module.__elixir_mock__call_exists(fn_name, args)
      call_string = build_call_string(fn_name, args)
      refute called, "Did not expect #{call_string} to be called but it was."
    end
  end

  defmacro assert_called({{:., _, [mock_ast, fn_name]}, _, args}) do
    quote bind_quoted: [mock_ast: mock_ast, fn_name: fn_name, args: args] do
      {mock_module, _} = Code.eval_quoted(mock_ast)
      {called, existing_calls} = mock_module.__elixir_mock__call_exists(fn_name, args)

      call_string = build_call_string(fn_name, args)
      existing_calls_string = build_calls_string(existing_calls)
      failure_message = "Expected #{call_string} to have been called but it was not found among calls:
       * #{existing_calls_string}"

      assert called, failure_message
    end
  end

  defmacro with_mock(mock_var_name) do
    quote do
      {_, unquote(mock_var_name), _, _}
    end
  end

  @doc false
  def verify_mock_structure(mock_fns, real_module) do
    real_functions = real_module.__info__(:functions)
    invalid_stubs =
      mock_fns
      |> Enum.filter(fn {fn_type, _} -> fn_type == :def end)
      |> Enum.filter(fn {:def, stub} -> not stub in real_functions end)
      |> Enum.map(fn {:def, stub} -> stub end)

    if not Enum.empty?(invalid_stubs) do
      ElixirMock.MockDefinitionError.raise_it(invalid_stubs, real_module)
    end
  end

  defp should_call_through_unstubbed_functions({:__block__, _, contents}) do
    contents
    |> Enum.filter(fn {member_type, _, _} -> member_type == :@ end)
    |> Enum.any?(fn {_, _, [{attr_name, _, [attr_val]}]} ->
      attr_name == :call_through_undeclared_functions and attr_val == true
    end)
  end

  defp should_call_through_unstubbed_functions(_non_block_mock), do: false

  defp unstubbed_fns_ast(real_module, stubs, call_through) do
    quote do
      unstubbed_fns =
        unquote(real_module).__info__(:functions)
        |> Enum.filter(fn {fn_name, arity} -> not {fn_name, arity} in unquote(stubs) end)
        |> Enum.map(fn {fn_name, arity} -> {fn_name, arity, unquote(call_through)} end)

      ElixirMock.inject_monitored_real_functions(unquote(real_module), unstubbed_fns)
    end
  end

  defp random_module_name, do: :"#{UUID.uuid4(:hex)}"

  defp random_arg_name, do: :"elixir_mock_unignored__#{UUID.uuid4(:hex)}"

  defp build_fn_spec(fn_type, fn_name, args) do
    arity = case args do
      nil -> 0
      list -> length(list)
    end
    {fn_type, {fn_name, arity}}
  end

  defp extract_mock_fns({:def, _, [{fn_name, _, args}, _]}),
    do: [build_fn_spec(:def, fn_name, args)]

  defp extract_mock_fns({:defp, _, [{fn_name, _, args}, _]}),
    do: [build_fn_spec(:defp, fn_name, args)]

  defp extract_mock_fns({:__block__, _, content_ast}) do
    content_ast
    |> Enum.filter(fn({member_type, _, _}) -> member_type in [:def, :defp] end)
    |> Enum.map(fn({fn_type, _, [{fn_name, _, args}, _]}) ->
      build_fn_spec(fn_type, fn_name, args)
    end)
  end

  defp cleanup_ignored_args(nil), do: nil

  defp cleanup_ignored_args(args) do
    Enum.map args, fn
      {:_, context, nil} -> {random_arg_name(), context, nil}
      used_argument -> used_argument
    end
  end

  defp inject_elixir_mock_utility_lines(lines, fn_name, args) when is_list(lines) do
    {:__block__, [], storage_call_lines} = quote do
      watcher_proc = MockWatcher.get_watcher_name_for(__MODULE__)
      GenServer.call(watcher_proc, {:record_call, unquote(fn_name), unquote(args)})
    end
    [do: {:__block__, [], storage_call_lines ++ lines}]
  end

  defp inject_elixir_mock_function_utilities({:def, _, [{fn_name, _, args}, _]} = fn_ast) do
    clean_args = cleanup_ignored_args(args)
    Macro.postwalk(fn_ast, fn
      [do: plain_value]            -> inject_elixir_mock_utility_lines([plain_value], fn_name, clean_args)
      [do: {:__block__, _, lines}] -> inject_elixir_mock_utility_lines(lines, fn_name, clean_args)
      {^fn_name, context, _}       -> {fn_name, context, clean_args}
      anything_else -> anything_else
    end)
  end

  defp inject_elixir_mock_function_utilities({:__block__, _, _} = block) do
    Macro.postwalk block, fn
      {:def, _, _} = fn_ast    -> inject_elixir_mock_function_utilities(fn_ast)
      anything_else            -> anything_else
    end
  end

  defp apply_stub_call_throughs({:def, _, [{fn_name, _, args}, _]} = fn_ast, real_module) do
    clean_args = if is_nil(args) do [] else args end
    call_through_ast = quote do
      unquote(real_module).unquote(fn_name)(unquote_splicing(clean_args))
    end
    Macro.postwalk fn_ast, fn
      :call_through -> call_through_ast
      anything_else -> anything_else
    end
  end

  defp apply_stub_call_throughs({:defp, _, _} = private_mock_fn_ast, _real_module), do: private_mock_fn_ast

  defp apply_stub_call_throughs({:__block__, _, content_ast}, real_module) do
    content_ast
    |> Enum.filter(fn({member_type, _, _}) -> member_type in [:def, :defp] end)
    |> Enum.map(fn(fn_ast) -> apply_stub_call_throughs(fn_ast, real_module) end)
  end

end