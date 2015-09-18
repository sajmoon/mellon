defmodule Mellon.Mixfile do
  use Mix.Project

  def project do
    [app: :mellon,
     version: "0.1.1-dev",
     elixir: "~> 1.0",
     name: "Mellon",
     deps: deps,
     package: package,
     description: description
    ]
  end

  defp package do
    [
      links: %{"GitHub" => "https://github.com/sajmoon/mellon"},
      contributors: ["Simon Ström"]
    ]
  end

  defp description do
    """
    Mellon is a Plug used in authentication of APIs.
    It's flexible, you can define your own validator etc.
    """
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: [:logger]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [
      {:plug, "> 0.8.0"},
      {:poison, ">= 1.3.1"}
    ]
  end
end
