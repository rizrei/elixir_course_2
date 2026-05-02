defmodule PlanningPoker.MixProject do
  use Mix.Project

  def project do
    [
      app: :planning_poker,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {PlanningPoker.Application, []}
    ]
  end

  defp deps do
    [
      {:dialyxir, "~> 1.4", only: [:dev], runtime: false},
      {:credo, "~> 1.7", only: [:dev], runtime: false}
    ]
  end
end
