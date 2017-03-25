defmodule Mockex do
  @moduledoc """
  Documentation for Mockex.
  """

  defp create_mock(real_module, mock_module_name) do
    module_defn = quote do
      @real_functions unquote(real_module).__info__(:functions)

      def f, do: 10

      def functions() do
        @real_functions
      end
    end
    
    Module.create(mock_module_name, module_defn, Macro.Env.location(__ENV__))
  end

  def of(real_module) do
    mod_name = :"#{UUID.uuid4(:hex)}"
    create_mock(real_module, mod_name)
    mod_name
  end

end