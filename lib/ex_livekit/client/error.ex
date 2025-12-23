defmodule ExLivekit.Client.Error do
  @moduledoc """
  Module for handling Twirp errors.
  """

  defstruct [:code, :msg, :meta, :status_code]

  @type code ::
          :canceled
          | :unknown
          | :invalid_argument
          | :malformed
          | :deadline_exceeded
          | :not_found
          | :bad_route
          | :already_exists
          | :permission_denied
          | :unauthenticated
          | :resource_exhausted
          | :failed_precondition
          | :aborted
          | :out_of_range
          | :unimplemented
          | :internal
          | :unavailable
          | :data_loss

  @type t :: %__MODULE__{
          code: code(),
          status_code: integer(),
          msg: String.t(),
          meta: %{String.t() => String.t()} | any()
        }

  @error_codes [
    :canceled,
    :unknown,
    :invalid_argument,
    :malformed,
    :deadline_exceeded,
    :not_found,
    :bad_route,
    :already_exists,
    :permission_denied,
    :unauthenticated,
    :resource_exhausted,
    :failed_precondition,
    :aborted,
    :out_of_range,
    :unimplemented,
    :internal,
    :unavailable,
    :data_loss
  ]

  @error_codes_map Map.new(@error_codes, &{to_string(&1), &1})

  @spec handle_error(
          {:ok, %{status: integer(), body: binary()}}
          | {:error, %{reason: ExLivekit.Client.HTTPClient.client_error_reason()}}
        ) ::
          {:error, t()}
  def handle_error({:ok, %{status: status_code, body: body}}) do
    case decode_body(body) do
      {:ok, %{"code" => code, "msg" => msg} = resp} ->
        {:error,
         %__MODULE__{
           status_code: status_code,
           code: Map.get(@error_codes_map, code, :unknown),
           msg: msg,
           meta: resp["meta"]
         }}

      {:error, reason} ->
        {:error,
         %__MODULE__{
           status_code: 500,
           code: :internal,
           msg: "Response is not JSON",
           meta: %{
             "body" => body,
             "decoder_error" => reason
           }
         }}
    end
  end

  def handle_error({:error, %{reason: reason}}) do
    {code, msg} =
      case reason do
        :connection_closed -> {:unavailable, "Connection closed"}
        :checkout_timeout -> {:deadline_exceeded, "Request timed out"}
        :econnrefused -> {:unavailable, "Connection refused"}
        :disconnected -> {:unavailable, "Disconnected"}
        :timeout -> {:deadline_exceeded, "Request timed out"}
        :unknown -> {:unknown, "Unknown Internal error"}
      end

    {:error,
     %__MODULE__{
       status_code: 500,
       code: code,
       msg: msg,
       meta: %{}
     }}
  end

  defp decode_body(body) do
    case Jason.decode(body) do
      {:ok, data} -> {:ok, data}
      {:error, _} -> {:error, body}
    end
  end
end
