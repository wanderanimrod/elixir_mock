# ElixirMock (alpha)

Creates mock modules based on real elixir modules for testing. The mocks are inspectable, don't replace the original
modules the are based on and are fully independent of each other. Because of this isolation, mocks defined from the same
real module can be used in multiple tests running in parallel.

## Installation

[Available in Hex](https://hex.pm/packages/elixir_mock). The package can be installed
by adding `elixir_mock` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:elixir_mock, "~> 0.2.2"}]
end
```

