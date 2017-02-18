defmodule UeberauthFitbit.Mixfile do
  use Mix.Project

  @version "0.2.3"
  @url "https://github.com/vinniefranco/ueberauth_fitbit"

  def project do
    [app: :ueberauth_fitbit,
     version: @version,
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     source_url: @url,
     homepage_url: @url,
     description: description(),
     package: package(),
     deps: deps()]
  end

  def application do
    [applications: [:logger, :oauth2, :ueberauth]]
  end

  defp deps do
    [{:ueberauth, "~> 0.4"},
      {:oauth2, "~> 0.8"},
      {:ex_doc, ">= 0.0.0", only: :dev}]
  end

  defp description do
    "An Ueberauth strategy for Fitbit OAuth2 authentication"
  end

  defp package do
    [files: ["lib", "mix.exs", "README.md", "LICENSE"],
     maintainers: ["Vincent Franco"],
     licenses: ["MIT"],
     links: %{ "Github": @url }]
  end
end
