defmodule ElixirMock.Mixfile do
  use Mix.Project

  def project do
    [
      app: :elixir_mock,
      version: "0.2.5",
      elixir: "~> 1.4",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      docs: docs()
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:uuid, "~> 1.1"},
      {:ex_doc, "~> 0.16.2", only: :dev, runtime: false}
    ]
  end

  defp description, do: "Creates inspectable mocks (test doubles) based on real elixir modules for testing."

  defp package() do
    [
      name: :elixir_mock,
      licenses: ["MIT"],
      links: %{"Github" => "https://github.com/wanderanimrod/elixir_mock"},
      source_url: "https://github.com/wanderanimrod/elixir_mock",
      maintainers: ["Wandera Nimrod"]
    ]
  end

  defp docs do
    [
      main: "getting_started",
      extras: ["extra_docs/getting_started.md"]
    ]
  end
end
