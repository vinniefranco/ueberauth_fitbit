Ueberauth Fitbit
====================

Fitbit strategy for Ueberauth

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Register your application at https://dev.fitbit.com/

  2. Add ueberauth_fitbit to your list of dependencies in `mix.exs`:

        def deps do
          [{:ueberauth_fitbit, "~> 0.2"}]
        end

  3. Ensure ueberauth_fitbit is started before your application:

        def application do
          [applications: [:ueberauth_fitbit]]
        end

  4. Add Fitbit to your Ueberauth configuration

        config :ueberauth, Ueberauth,
        providers: [
          fitbit: { Ueberauth.Strategy.Fitbit, [] }
        ]

  5.  Update your provider configuration:

        config :ueberauth, Ueberauth.Strategy.Twitter.Fitbit,
          consumer_key: System.get_env("FITBIT_CLIENT_ID"),
          consumer_secret: System.get_env("FITBIT_CLIENT_SECRET")

  6.  Include the Überauth plug in your controller:

        defmodule MyApp.AuthController do
          use MyApp.Web, :controller
          plug Ueberauth
          ...
        end

  7.  Create the request and callback routes if you haven't already:

        scope "/auth", MyApp do
          pipe_through :browser

          get "/:provider", AuthController, :request
          get "/:provider/callback", AuthController, :callback
        end

  8. You controller needs to implement callbacks to deal with `Ueberauth.Auth` and `Ueberauth.Failure` responses.


## Calling

Depending on the configured url you can initial the request through:

    /auth/fitbit
