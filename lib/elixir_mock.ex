defmodule ElixirMock do
  @moduledoc """
  This module contains functions and macros for creating mocks from real modules. It also contains utilities for
  verifying that calls were made to functions in the mocks.
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

  @doc """
  Creates a mock module from a real module allowing custom definitons for some or all of the functions on the mock.

  Mock behaviour can be tuned in a number of different ways depending on your needs. The next few sections enumerate the
  tuning options available with examples. We will use the inbuilt `List` module as our base module for these examples.

  ## Feature: Overriding functions

  Creating a mock from the `List` module and overriding its `List.first/1` function.

  ```
  require ElixirMock
  import ElixirMock

  with_mock(list_mock) = defmock_of List do
    def first(_list), do: :mock_response_from_first
  end

  list_mock.first([1, 2]) == :mock_response_from_first
  #=> true
  ```

  ## Feature: Delegating calls to the real module with `:call_through`

  When a function in a mock defintion returns the atom `:call_through`, ElixirMock will forward all calls made to that
  function to the corresponding function on the real module. All calls are still recorded by the mock and are inspectable
  with the `assert_called/1` and `refute_called/1` macros.

  ```
  require ElixirMock
  import ElixirMock

  with_mock(list_mock) = defmock_of List do
    def first(_list), do: :call_through
  end

  list_mock.first([1, 2]) == List.first([1, 2]) == 1
  #=> true
  ```

  ## Feature: Delegating unspecified function calls to the real module

  Sometimes, you only want to stub out specific functions on modules but leave other functions behaving as defined on the
  original module. This could be because the overriden functions have side-effects you don't want to deal with in your
  tests or because you want to alter the behaviour of just those functions so you can test code that depends on them.
  ElixirMock provides the `@call_through_undeclared_functions` mock attribute to help with this. Mocks defined with this
  attribute set to `true` will forward calls made to undeclared functions to the real module. Mocks defined without this
  attribute simply return `nil` when calls are made to undeclared functions.

  All functions calls, whether defined on the mock on not, are still recorded by the mock and are inspectable with the
  `assert_called/1` and `refute_called/1` macros.

  In the example below, the `List.first/1` function is overriden but the `List.last/1` function retains its original behaviour.
  ```
  require ElixirMock
  import ElixirMock

  with_mock(list_mock) = defmock_of List do
    @call_through_undeclared_functions true
    def first(_list), do: :mock_response_from_first
  end

  list_mock.first([1, 2]) == :mock_response_from_first
  list_mock.last([1, 2] == List.last([1, 2]) == 2
  #=> true
  ```

  ## Info: Mock functions only override function heads of the same arity in the real module.
  ```
  defmodule Real do
    def x, do: {:arity, 0}
    def x(_arg), do: {:arity, 1}
  end

  with_mock(mock) = defmock_of Real do
    def x, do: :overridden_x
  end

  mock.x == :overridden_x
  #=> true
  mock.x(:some_arg) == nil
  #=> true
  ```

  ## Notes
    - An `ElixirMock.MockDefinitionError` is raised if a _public_ function that does not exist in the real module is
    declared on the mock.
    - Mocks allow private functions to be defined on them. These functions needn't be defined on the real module. In fact,
    private functions are not imported from the real module into the mock at all.
    - Please refer to the [Getting started guide](getting_started.html) for a broader enumeration of the
    characteristics of ElixirMock's mocks.
  """
  defmacro defmock_of(real_module, do: nil) do
    mock_name = random_module_name()
    quote do
      ElixirMock.create_mock(unquote(real_module), unquote(mock_name))
    end
  end

  @doc """
  Creates a mock module from a real module just like `defmock_of/2` but additionally allows a context map to be injected
  into the mock definition.

  The context injected in the mock is accessible to the functions within the mock definition via the
  `ElixirMock.Mock.context/2` function. It takes in the context key and a mock and looks up the key's value in the
  context map passed to mock when it was defined. An `ArgumentError` is thrown if the key doesn't exist in the context
  map.

  Being able to pass context into mocks is very useful when you need to fix the behaviour of a mock using some values
  declared outside the mock's definition.

  Example:

  ```
  require ElixirMock
  import ElixirMock

  fixed_first = 100

  with_mock(list_mock) = defmock_of List, %{fixed_first: fixed_first} do
    def first(_list), do: ElixirMock.Mock.context(:fixed_first, __MODULE__)
  end

  list_mock.first([1, 2]) == fixed_first
  #=> true
  ```

  For more on the options available within mock definitions, see `defmock_of/2`
  """
  defmacro defmock_of(real_module, context \\ {:%{}, [], []}, do: mock_ast) do
    call_through_unstubbed_fns = call_through_unstubbed_functions?(mock_ast)
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

  @doc """
  Creates mock from real module with all functions on real module defined on the the mock.

  By default, all functions on the mock return nil. The behaviour of the module the mock is defined from remains intact.

  ```
  defmodule MyRealModule do
    def function_one(_), do: :real_result
  end

  require ElixirMock
  import ElixirMock

  my_mock = mock_of MyRealModule

  # functions on mock return nil
  my_mock.function_one(1) == nil
  #=> true

  # the real module is still intact
  MyRealModule.function_one(1) == :real_result
  #=> true
  ```

  ### `call_through`
  When `:call_through` is provided, functions defined on the mock delegate all calls to the corresponding functions on the
  real module.

  ```
  transparent_mock = mock_of MyRealModule, :call_through
  transparent_mock.function_one(1) == MyRealModule.function_one(1) == :real_result
  #=> true
  ```
  """
  @spec mock_of(module, atom) :: ElixirMock.Mock.mock
  def mock_of(real_module, :call_through),
    do: mock_of(real_module, true)

  def mock_of(real_module, call_through) do
    mod_name = random_module_name()
    create_mock(real_module, mod_name, call_through)
    mod_name
  end

  @doc """
  Verifies that a function on a mock was not called.

  ```
  defmodule MyTest do
    use ExUnit.Case
    require ElixirMock
    import ElixirMock

    test "verifies that function on mock was not called" do
      mock = mock_of List
      mock.first [1, 2]
      refute_called mock.first(:some_other_arg) # passes
      refute_called mock.first([1, 2]) # fails!
    end
  end
  ```
  _Note that the function call expressions passed to the macro are not executed. Rather, they are deconstructed to get the function
  name and the arguments. The function name and arguments are then used to find the call in the mocks recorded list of calls._

  When `refute_called/1` is given a matcher, the macro makes the test pass if the matcher evaluates to false for *all*
  recorded calls. See `ElixirMock.Matchers` for more juicy details on Matchers.

  ```
  defmodule MyTest do
    use ExUnit.Case
    require ElixirMock
    import ElixirMock
    alias ElixirMock.Matchers

    test "verifies that function on mock was not called" do
      mock = mock_of List
      mock.first [1, 2]
      refute_called mock.first(Matchers.any(:number)) # passes
      refute_called mock.first(Matchers.any(:list)) # fails!
    end
  end
  ```
  """
  defmacro refute_called({{:., _, [mock_ast, fn_name]}, _, args} = _function_call_expression) do
    quote bind_quoted: [mock_ast: mock_ast, fn_name: fn_name, args: args] do
      {mock_module, _} = Code.eval_quoted(mock_ast)

      {called, _existing_calls} = mock_module.__elixir_mock__call_exists(fn_name, args)
      call_string = build_call_string(fn_name, args)
      refute called, "Did not expect #{call_string} to be called but it was."
    end
  end

  @doc """
  Verifies that a function on a mock was called.

  ```
  defmodule MyTest do
    use ExUnit.Case
    require ElixirMock
    import ElixirMock

    test "verifies that function on mock was called" do
      mock = mock_of List
      mock.first [1, 2]
      assert_called mock.first([1, 2]) # passes
      assert_called mock.first(:some_other_arg) # fails!
    end
  end
  ```

  _Note that the function call expressions passed to the macro are not executed. Rather, they are deconstructed to get the function
  name and the arguments. The function name and arguments are then used to find the call in the mocks recorded list of calls._

  When `assert_called/1` is given a matcher, the macro makes the test pass if the matcher
  evaluates to true for any recorded call. See `ElixirMock.Matchers` for more juicy details on Matchers.

  ```
  defmodule MyTest do
    use ExUnit.Case
    require ElixirMock
    import ElixirMock
    alias ElixirMock.Matchers

    test "verifies that function on mock was called" do
      mock = mock_of List
      mock.first [1, 2]
      assert_called mock.first(Matchers.any(:list)) # passes
      assert_called mock.first(Matchers.any(:atom)) # fails!
    end
  end
  ```
  """
  defmacro assert_called({{:., _, [mock_ast, fn_name]}, _, args} = _function_call_expression) do
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

  @doc """
  A light wrapper that assigns names to mocks created with the `defmock_of/3` and `defmock_of/2` macros.

  This is necessary because `defmock_of/3` and `defmock_of/2` return random mock module names wrapped in an ast tuple.
  This little macro helps you give the random mock module a human-friendly name.

  Example:
  ```
  require ElixirMock
  import ElixirMock

  with_mock(my_custom_mock) = defmock_of List do end

  # you can then use 'my_custom_mock' as a normal module
  my_custom_mock.first([1, 2])
  #=> nil
  ```
  """
  defmacro with_mock(mock_name) do
    quote do
      {_, unquote(mock_name), _, _}
    end
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

      def __elixir_mock__reset do
        :ok = GenServer.call(@watcher_proc, :clear_calls)
      end

      def __elixir_mock__list_calls,
        do: GenServer.call(@watcher_proc, :list_calls)

      def __elixir_mock__mock_context(key) when is_atom(key) do
        if Map.has_key?(@mock_context, key) do
          Map.get(@mock_context, key)
        else
          raise ArgumentError, "#{inspect key} not found in mock context #{inspect @mock_context}"
        end
      end
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

  defp call_through_unstubbed_functions?({:__block__, _, contents}) do
    contents
    |> Enum.filter(fn {member_type, _, _} -> member_type == :@ end)
    |> Enum.any?(fn {_, _, [{attr_name, _, [attr_val]}]} ->
      attr_name == :call_through_undeclared_functions and attr_val == true
    end)
  end

  defp call_through_unstubbed_functions?(_non_block_mock), do: false

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