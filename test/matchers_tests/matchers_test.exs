defmodule ElixirMock.MatchersTest do
  use ExUnit.Case, async: true
  require ElixirMock

  import ElixirMock.Matchers
  import ElixirMock

  defmodule RealModule do
    def function_one(_), do: :real_result_one
    def function_two(_, _), do: :real_result_two
  end

  test "should test if function was called with integer arguments" do
    mock = mock_of RealModule

    mock.function_one(:not_an_int)
    refute_called mock.function_one(any(:integer))

    mock.function_one(1)
    assert_called mock.function_one(any(:integer))
  end

  test "should test function args with custom matcher" do
    a_person_over_30_years_old = {:matches, fn(%{age: age}) -> age > 30 end}

    mock = mock_of RealModule

    mock.function_one(%{age: 20})
    refute_called mock.function_one(a_person_over_30_years_old)

    mock.function_one(%{age: 40})
    assert_called mock.function_one(a_person_over_30_years_old)
  end

  test "should provide convenience 'any()' wrapper to match anything" do
    assert any() == {:matches, ElixirMock.Matchers.InBuilt.any(:_)}
  end

  test "should provide 'any(type)' wrapper to generate matcher statement for type" do
    assert any(:integer) == {:matches, ElixirMock.Matchers.InBuilt.any(:integer)}
  end

  test "should provide 'literal' wrapper to generate matcher statement for args that are matchers" do
    assert literal({:matches, 10}) == {:__elixir_mock__literal, {:matches, 10}}
  end

  test "should 'deep match' on map argument expectations" do
    mock = mock_of RealModule
    mock.function_one %{key_one: :val_one, key_two: :val_two}
    assert_called mock.function_one(%{key_one: {:matches, fn val -> val == :val_one end}, key_two: :val_two})
  end

  test "should not deep match on map argument expectations if actual args are not a map" do
    mock = mock_of RealModule
    mock.function_one 10
    refute_called mock.function_one(%{key: {:matches, fn _ -> true end}})
  end

  test "'deep matching' should be recursive" do
    is_eq_10 = {:matches, fn val -> val == 10 end}
    mock = mock_of RealModule

    mock.function_one %{key_1: %{key_2: %{key_3: 10}}}

    assert_called mock.function_one(%{key_1: %{key_2: %{key_3: is_eq_10}}})
  end

  test "should not match map arguments when keys missing in expected map are present in actual map" do
    mock = mock_of RealModule
    mock.function_one %{key: 1, other_key: 2}
    refute_called mock.function_one(%{key: 1})
  end
end