defmodule Ueberauth.Strategy.Fitbit.OAuth do
  @moduledoc """
  OAuth2 for Fitbit.

  Add `client_id` and `client_secret` to your configuration:

  config :ueberauth, Ueberauth.Strategy.Fitbit.OAuth,
    client_id: System.get_env("FITBIT_APP_ID"),
    client_secret: System.get_env("FITBIT_APP_SECRET")
  """
  use OAuth2.Strategy

  @defaults [
    strategy: __MODULE__,
    site: "https://api.fitbit.com",
    authorize_url: "https://www.fitbit.com/oauth2/authorize",
    token_url: "https://api.fitbit.com/oauth2/token",
    headers: [{"Content-Type", "application/x-www-form-urlencoded"}]
  ]

  @doc false
  def options(opts \\ [], app \\ Application) do
    config = app.get_env(:ueberauth, Ueberauth.Strategy.Fitbit.OAuth)

    @defaults
    |> Keyword.merge(config)
    |> Keyword.merge(opts)
  end

  @doc """
  Generate Authentication: Basic Base64<CLIENT_ID>:<CLIENT_SECRET>
  """
  def auth_sig(opts \\ []) do
    opts = options(opts)
    sig = Base.encode64(opts[:client_id] <> ":" <> opts[:client_secret])

    "Basic #{sig}"
  end

  @doc """
  Construct a client for requests to Fitbit.

  This will be setup automatically for you in `Ueberauth.Strategy.Fitbit`.
  These options are only useful for usage outside the normal callback phase of Ueberauth.
  """
  def client(opts \\ []) do
    OAuth2.Client.new(options(opts))
  end

  @doc """
  Construct a signed client for token and refresh token requests
  """
  def signed_client(opts \\ []) do
    opts
    |> client
    |> put_header("Authorization", auth_sig(opts))
  end

  @doc """
  Provides the authorize url for the request phase of Ueberauth. No need to call this usually.
  client_id:client_secret
  """
  def authorize_url!(params \\ [], opts \\ []) do
    opts
    |> client
    |> OAuth2.Client.authorize_url!(params)
  end

  def get(token, url, headers \\ [], opts \\ []) do
    client([token: token])
    |> put_param("client_secret", client().client_secret)
    |> OAuth2.Client.get(url, headers, opts)
  end

  def get_token!(params \\ [], opts \\ []) do
    opts
    |> signed_client
    |> OAuth2.Client.get_token!(params)
  end

  # Strategy Callbacks

  def authorize_url(client, params) do
    OAuth2.Strategy.AuthCode.authorize_url(client, params)
  end

  def get_token(client, params, headers) do
    client
    |> put_header("Accept", "application/json")
    |> OAuth2.Strategy.AuthCode.get_token(params, headers)
  end

end
