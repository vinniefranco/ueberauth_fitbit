defmodule Ueberauth.Strategy.Fitbit do
  @moduledoc """
  Fitbit Strategy for Üeberauth.
  """

  use Ueberauth.Strategy, uid_field: :user_id,
                          default_scope: "activity nutrition profile settings sleep social weight"

  alias Ueberauth.Auth.Info
  alias Ueberauth.Auth.Credentials
  alias Ueberauth.Auth.Extra

  @doc """
  Handles initial request for Fitbit authentication.
  """
  def handle_request!(conn) do
    scopes = conn.params["scope"] || option(conn, :default_scope)
    opts = [ scope: scopes ]
    if conn.params["state"], do: opts = Keyword.put(opts, :state, conn.params["state"])
    opts = Keyword.put(opts, :redirect_uri, callback_url(conn))

    IO.inspect opts

    redirect!(conn, Ueberauth.Strategy.Fitbit.OAuth.authorize_url!(opts))
  end

  @doc """
  Handles the callback from Fitbit.
  """
  def handle_callback!(%Plug.Conn{ params: %{ "code" => code } } = conn) do
    opts = [redirect_uri: callback_url(conn)]
    token = Ueberauth.Strategy.Fitbit.OAuth.get_token!([code: code], opts)

    if token.access_token == nil do
      set_errors!(conn, [error(token.other_params["error"], token.other_params["error_description"])])
    else
      fetch_user(conn, token)
    end
  end

  @doc false
  def handle_callback!(conn) do
    set_errors!(conn, [error("missing_code", "No code received")])
  end

  @doc false
  def handle_cleanup!(conn) do
    conn
    |> put_private(:fitbit_user, nil)
    |> put_private(:fitbit_token, nil)
  end

  @doc """
  Fetches the uid field from the response.
  """
  def uid(conn) do
    uid_field =
      conn
      |> option(:uid_field)
      |> to_string

    conn.private.fitbit_user[uid_field]
  end

  @doc """
  Includes the credentials from the fitbit response.
  """
  def credentials(conn) do
    token = conn.private.fitbit_token
    scopes = (token.other_params["scope"] || "") |> String.split(",")

    %Credentials{
      expires: !!token.expires_at,
      expires_at: token.expires_at,
      scopes: scopes,
      token: token.access_token
    }
  end

  @doc """
  Fetches the fields to populate the info section of the `Ueberauth.Auth` struct.
  """
  def info(conn) do
    user = conn.private.fitbit_user

    %Info{
      name: user["displayName"],
      nickname: user["nickname"]
    }
  end

  @doc """
  Stores the raw information (including the token) obtained from the fitbit callback.
  """
  def extra(conn) do
    user = conn.private.fitbit_user

    %Extra{
      raw_info: %{
        token: conn.private.fitbit_token,
        user: conn.private.fitbit_user,
        gender: user["gender"],
        about_me: user["aboutMe"],
        city: user["city"],
        state: user["state"]
      }
    }
  end

  defp fetch_user(conn, token) do
    conn = put_private(conn, :fitbit_token, token)

    case OAuth2.AccessToken.get(token, "https://api.fitbit.com/1/user/-/profile.json") do
      { :ok, %OAuth2.Response{status_code: 401, body: _body } } ->
        set_errors!(conn, [error("token", "unauthorized")])
      { :ok, %OAuth2.Response{ status_code: status_code, body: user } } when status_code in 200..399 ->
        put_private(conn, :fitbit_user, user)
      { :error, %OAuth2.Error{ reason: reason } } ->
        set_errors!(conn, [error("OAuth2", reason)])
    end
  end

  defp option(conn, key) do
    Dict.get(options(conn), key, Dict.get(default_options, key))
  end

end
