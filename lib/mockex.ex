defmodule Mockex do
  @moduledoc """
  Documentation for Mockex.
  """

  defmacrop mock(_module, mod_name) do
    quote do
      defmodule unquote(mod_name) do
        def f, do: 10
      end
    end
  end

  def of(module) do
    mod_name = :mock_mod
    mock(module, mod_name)
    mod_name
  end

end

