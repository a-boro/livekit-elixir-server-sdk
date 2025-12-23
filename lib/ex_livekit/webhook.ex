defmodule ExLivekit.Webhook do
  @moduledoc """
  Module for receiving and validating LiveKit webhook events.

  This module provides functionality to receive and validate LiveKit webhook events.
  It handles webhook event validation, token verification, and SHA256 validation.
  """

  alias ExLivekit.Grants.ClaimGrant
  alias ExLivekit.TokenVerifier

  @type config :: %{api_key: binary(), api_secret: binary()}
  @type webhook_error :: :webhook_not_configured | :invalid_token | :invalid_sha256

  @doc """
  Receives a LiveKit webhook event and validates the token and SHA256.

  ## Examples

  ```elixir
  {:ok, event} = ExLivekit.Webhook.receive_event(event, auth_token)
  ```


  The auth_token can be a JWT token or a Bearer token.

  ```elixir
  {:ok, event} = ExLivekit.Webhook.receive_event(event, "Bearer auth_token")
  {:ok, event} = ExLivekit.Webhook.receive_event(event, "auth_token")
  ```
  """
  @spec receive_event(event :: binary(), auth_token :: binary()) ::
          {:ok, Livekit.WebhookEvent.t()} | {:error, webhook_error}
  def receive_event(event, "Bearer " <> auth_token), do: receive_event(event, auth_token)

  def receive_event(event, auth_token) do
    with {:ok, config} <- get_webhook_config(),
         {:ok, %ClaimGrant{} = claims_grant} <-
           validate_token(auth_token, config.api_key, config.api_secret),
         :ok <- validate_sha256(event, claims_grant.sha256) do
      decode_event(event)
    end
  end

  @spec validate_token(auth_token :: binary(), api_key :: binary(), api_secret :: binary()) ::
          {:ok, %ClaimGrant{}} | {:error, :invalid_token}
  defp validate_token(auth_token, api_key, api_secret) do
    case TokenVerifier.verify(auth_token,
           verify_signature: true,
           api_key: api_key,
           api_secret: api_secret
         ) do
      {:ok, _jwt_claims, %ClaimGrant{} = claims_grant} -> {:ok, claims_grant}
      {:error, _reason} -> {:error, :invalid_token}
    end
  end

  @doc false
  @spec validate_sha256(event :: binary(), sha256 :: binary()) ::
          :ok | {:error, :invalid_sha256}
  def validate_sha256(_event, sha256) when sha256 in [nil, ""] do
    {:error, :invalid_sha256}
  end

  def validate_sha256(event, sha256) do
    with body_hash = :crypto.hash(:sha256, event),
         {:base64, {:ok, claims_hash}} <- {:base64, Base.decode64(sha256)},
         {:hash_match, true} <- {:hash_match, body_hash == claims_hash} do
      :ok
    else
      _error -> {:error, :invalid_sha256}
    end
  end

  defp decode_event(event) do
    case Protobuf.JSON.decode(event, Livekit.WebhookEvent) do
      {:ok, decoded_event} -> {:ok, decoded_event}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc false
  @spec get_webhook_config() :: {:ok, config()} | {:error, :webhook_not_configured}
  def get_webhook_config do
    env = Application.get_all_env(:ex_livekit)

    case Keyword.get(env, :webhook) do
      nil -> get_credentials(env)
      config -> get_credentials(config)
    end
  end

  defp get_credentials(env) do
    api_key = Keyword.get(env, :api_key)
    api_secret = Keyword.get(env, :api_secret)

    if is_nil(api_key) or is_nil(api_secret) do
      {:error, :webhook_not_configured}
    else
      {:ok, %{api_key: api_key, api_secret: api_secret}}
    end
  end
end
