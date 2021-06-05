defmodule Tyx.MixProject do
  use Mix.Project

  @app :tyx
  @version "0.0.2"

  def project do
    [
      app: @app,
      version: @version,
      elixir: "~> 1.12",
      compilers: compilers(Mix.env()),
      elixirc_paths: elixirc_paths(Mix.env()),
      consolidate_protocols: Mix.env() not in [:dev, :test],
      preferred_cli_env: [credo: :ci, ci: :ci, tyx: :tyx],
      description: description(),
      package: package(),
      deps: deps(),
      aliases: aliases(),
      docs: docs(),
      dialyzer: [
        plt_file: {:no_warn, ".dialyzer/dialyzer.plt"},
        plt_add_deps: :app_tree,
        plt_add_apps: [:mix],
        plt_ignore_apps: [],
        list_unused_filters: true,
        ignore_warnings: ".dialyzer/ignore.exs"
      ]
    ]
  end

  def application, do: [extra_applications: [:logger]]

  defp deps do
    [
      {:boundary, "~> 0.4", runtime: false},
      # dev, ci
      {:credo, "~> 1.0", only: :ci, runtime: false},
      {:dialyxir, "~> 1.0", only: :ci, runtime: false},
      {:ex_doc, "~> 0.11", only: :dev, runtime: false}
    ]
  end

  defp aliases do
    [
      ci: [
        "format --check-formatted",
        "credo --strict",
        "dialyzer"
      ],
      tyx: ["clean", "compile"]
    ]
  end

  defp description do
    """
    Library bringing types support to elixir.

    Allows type validation in compile time.
    """
  end

  defp package do
    [
      name: @app,
      files: ~w|lib .formatter.exs .dialyzer/ignore.exs mix.exs README* LICENSE|,
      maintainers: ["Aleksei Matiushkin"],
      licenses: ["Kantox LTD"],
      links: %{
        "GitHub" => "https://github.com/am-kantox/#{@app}",
        "Docs" => "https://hexdocs.pm/#{@app}"
      }
    ]
  end

  defp docs do
    [
      main: "getting-started",
      source_ref: "v#{@version}",
      canonical: "http://hexdocs.pm/#{@app}",
      logo: "stuff/#{@app}-48x48.png",
      source_url: "https://github.com/am-kantox/#{@app}",
      assets: "stuff/images",
      extras: ~w[stuff/getting-started.md],
      groups_for_modules: [
        Internals: [],
        Examples: []
      ]
    ]
  end

  defp elixirc_paths(:dev), do: ["lib", "test/support"]
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp compilers(:prod), do: Mix.compilers()
  # defp compilers(:tyx), do: [:tyx | Mix.compilers()]
  defp compilers(_), do: [:boundary | Mix.compilers()]
end
