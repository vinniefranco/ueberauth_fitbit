defmodule UeberauthFitbit.Mixfile do
  use Mix.Project

  @version "0.0.1"
  @url "https:/github.com/vinniefranco/ueberauth_fitbi"

  def project do
    [app: :ueberauth_fitbit,
     version: @version,
     elixir: "~> 1.1",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     source_url: @url,
     homepage_url: @url,
     description: description,
     deps: deps]
  end

  def application do
    [applications: [:logger, :oauth2, :ueberauth]]
  end

  defp deps do
    [
      {:ueberauth, "~> 0.2"},
      {:oauth2, "~> 0.5"}
    ]
  end

  defp description do
    "An Ueberauth strategy for Fitbit OAuth2 authentication"
  end
end
