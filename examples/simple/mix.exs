defmodule Simple.MixProject do
  use Mix.Project

  def project do
    [
      app: :simple,
      version: "0.1.0",
      elixir: "~> 1.12",
      compilers: [:tyx | Mix.compilers()],
      aliases: [compile: ["clean", "compile"]],
      start_permanent: Mix.env() == :prod,
      deps: [{:tyx, path: "../../../tyx"}]
    ]
  end

  def application, do: [extra_applications: [:logger]]
end
