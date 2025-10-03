defmodule Help.MixProject do
  use Mix.Project

  @script_name "exh"

  def project do
    [
      app: :help,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: script(),
    ]
  end

  def script do
    [
      main_module: FzfHelper.Cli,
      name: @script_name
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      env: [script_name: @script_name],
      extra_applications: [:logger],
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
