defmodule Ueberauth.Strategy.Fitbit do
  @moduledoc """
  Fitbit Strategy for Üeberauth.
  """

  use Ueberauth.Strategy, uid_field: :user_id,
                          default_scope: "activity nutrition profile settings sleep social weight",
                          oauth2_module: Ueberauth.Strategy.Fitbit.OAuth

  alias Ueberauth.Auth.Info
  alias Ueberauth.Auth.Credentials
  alias Ueberauth.Auth.Extra

  @doc """
  Handles initial request for Fitbit authentication.
  """
  def handle_request!(conn) do
    scopes = conn.params["scope"] || option(conn, :default_scope)
    opts = [redirect_uri: callback_url(conn), scope: scopes]

    opts =
      if conn.params["state"], do: Keyword.put(opts, :state, conn.params["state"]), else: opts

    module = option(conn, :oauth2_module)
    redirect!(conn, apply(module, :authorize_url!, [opts]))
  end

  @doc """
  Handles the callback from Fitbit.
  """
  def handle_callback!(%Plug.Conn{ params: %{ "code" => code } } = conn) do
    opts = [redirect_uri: callback_url(conn)]
    client = Ueberauth.Strategy.Fitbit.OAuth.get_token!([code: code], opts)
    token = client.token

    if token.access_token == nil do
      set_errors!(conn, [error(token.other_params["error"], token.other_params["error_description"])])
    else
      # We need to reset the client in the token here because it has basic auth in the headers
      fetch_user(conn, Map.put(token, :client, Ueberauth.Strategy.Fitbit.OAuth.client))
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
    # user id is the only reasonable uid field for this strategy
    Map.get(conn.private.fitbit_token.other_params, "user_id")
  end

  @doc """
  Includes the credentials from the fitbit response.
  """
  def credentials(conn) do
    token = conn.private.fitbit_token
    scopes = (token.other_params["scope"] || "") |> String.split(" ")

    %Credentials{
      expires: !!token.expires_at,
      expires_at: token.expires_at,
      scopes: scopes,
      token: token.access_token,
      refresh_token: token.refresh_token,
      other: %{ token_type: token.token_type }
    }
  end

  @doc """
  Fetches the fields to populate the info section of the `Ueberauth.Auth` struct.
  """
  def info(conn) do
    user = conn.private.fitbit_user

    %Info{
      name: user["fullName"] || user["displayName"],
      nickname: user["nickname"] || user["displayName"],
      description: user["aboutMe"],
      image: user["avatar"],
      urls: %{
        avatar: user["avatar"],
        avatar150: user["avatar150"]
      }
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
        city: user["city"],
        state: user["state"]
      }
    }
  end

  defp fetch_user(conn, token) do
    conn = put_private(conn, :fitbit_token, token)

    case Ueberauth.Strategy.Fitbit.OAuth.get(token, "/1/user/-/profile.json") do
      { :ok, %OAuth2.Response{status_code: 401, body: _body } } ->
        set_errors!(conn, [error("token", "unauthorized")])
      { :ok, %OAuth2.Response{ status_code: status_code, body: res } } when status_code in 200..399 ->
        put_private(conn, :fitbit_user, res["user"])
      { :error, %OAuth2.Error{ reason: reason } } ->
        set_errors!(conn, [error("OAuth2", reason)])
    end
  end

  defp option(conn, key) do
    Keyword.get(options(conn), key, Keyword.get(default_options(), key))
  end

end
