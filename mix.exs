defmodule ElixirMock.Mixfile do
  use Mix.Project

  def project do
    [
      app: :elixir_mock,
      version: "0.2.2",
      elixir: "~> 1.4",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      description: description(),
      package: package(),
      deps: deps()
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

  defp description do
    """
    Creates mock modules based on real elixir modules for testing. The mocks are inspectable, don't replace the original
    modules the are based on and fully independent of each other. Because of this isolation, mocks defined from the same
    real module can be used in multiple tests in parallel.
    """
  end

  defp package() do
    [
      name: :elixir_mock,
      licenses: ["MIT"],
      links: %{"Github" => "https://github.com/wanderanimrod/elixir_mock"},
      source_url: "https://github.com/wanderanimrod/elixir_mock",
      maintainers: ["Wandera Nimrod"]
    ]
  end
end
