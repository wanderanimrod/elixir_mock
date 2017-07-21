defmodule ElixirMock.Mock do
  @moduledoc """
  Contains functions that examine mocks and manipulate their state
  """

  def context(key, mock) do
    mock.__elixir_mock__mock_context(key)
  end

  def list_calls(mock) do
    mock.__elixir_mock__list_calls
  end

  def clear_calls(mock) do
    mock.__elixir_mock__reset
  end
end