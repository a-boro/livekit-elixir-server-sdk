defmodule ExLivekit.Client.ErrorTest do
  use ExUnit.Case, async: true
  alias ExLivekit.Client.Error

  describe "handle_error/1 with {:ok, response}" do
    test "handles valid Twirp error response with known error code" do
      error_code_string = "not_found"
      error_code_atom = :not_found
      error_message = "Room not found"
      status_code = 404

      body = Jason.encode!(%{"code" => error_code_string, "msg" => error_message})
      response = {:ok, %{status: status_code, body: body}}

      assert {:error, error} = Error.handle_error(response)

      assert error.code == error_code_atom
      assert error.status_code == status_code
      assert error.msg == error_message
      assert error.meta == nil
    end

    test "handles Twirp error response with meta field" do
      error_code_string = "permission_denied"
      error_code_atom = :permission_denied
      error_message = "Access denied"
      status_code = 403
      meta = %{"room_id" => "room123", "user_id" => "user456"}

      body = Jason.encode!(%{"code" => error_code_string, "msg" => error_message, "meta" => meta})
      response = {:ok, %{status: status_code, body: body}}

      assert {:error, error} = Error.handle_error(response)

      assert error.code == error_code_atom
      assert error.status_code == status_code
      assert error.msg == error_message
      assert error.meta == meta
    end

    @error_codes [
      "canceled",
      "unknown",
      "invalid_argument",
      "malformed",
      "deadline_exceeded",
      "not_found",
      "bad_route",
      "already_exists",
      "permission_denied",
      "unauthenticated",
      "resource_exhausted",
      "failed_precondition",
      "aborted",
      "out_of_range",
      "unimplemented",
      "internal",
      "unavailable",
      "data_loss"
    ]
    for code_string <- @error_codes do
      test "handles Twirp error code: #{code_string}" do
        test_message = "Test message"
        default_status_code = 500
        code_string = unquote(code_string)

        body = Jason.encode!(%{"code" => code_string, "msg" => test_message})
        response = {:ok, %{status: default_status_code, body: body}}

        assert {:error, error} = Error.handle_error(response)
        assert error.code == String.to_atom(code_string)
        assert error.msg == test_message
      end
    end

    test "handles unknown error code by defaulting to :unknown" do
      unknown_code_string = "custom_error_code"
      expected_code_atom = :unknown
      error_message = "Custom error"
      status_code = 500

      body = Jason.encode!(%{"code" => unknown_code_string, "msg" => error_message})
      response = {:ok, %{status: status_code, body: body}}

      assert {:error, error} = Error.handle_error(response)

      assert error.code == expected_code_atom
      assert error.status_code == status_code
      assert error.msg == error_message
    end

    test "handles different HTTP status codes" do
      status_codes = [400, 401, 403, 404, 429, 500, 503]
      error_code_string = "internal"
      error_message = "Error message"

      for status_code <- status_codes do
        body = Jason.encode!(%{"code" => error_code_string, "msg" => error_message})
        response = {:ok, %{status: status_code, body: body}}

        assert {:error, error} = Error.handle_error(response)
        assert error.status_code == status_code
      end
    end

    test "handles invalid JSON body" do
      invalid_body = "not valid json"
      expected_code = :internal
      expected_status_code = 500
      expected_message = "Response is not JSON"

      response = {:ok, %{status: expected_status_code, body: invalid_body}}

      assert {:error, error} = Error.handle_error(response)

      assert error.code == expected_code
      assert error.status_code == expected_status_code
      assert error.msg == expected_message
      assert error.meta["body"] == invalid_body
      assert error.meta["decoder_error"] == invalid_body
    end

    test "handles empty JSON body" do
      empty_body = ""
      expected_code = :internal
      expected_status_code = 500
      expected_message = "Response is not JSON"

      response = {:ok, %{status: expected_status_code, body: empty_body}}

      assert {:error, error} = Error.handle_error(response)

      assert error.code == expected_code
      assert error.status_code == expected_status_code
      assert error.msg == expected_message
    end

    test "raises CaseClauseError when JSON body is missing required fields" do
      error_message = "Error message"
      error_code_string = "internal"
      status_code = 500

      # Missing "code" field
      body1 = Jason.encode!(%{"msg" => error_message})
      response1 = {:ok, %{status: status_code, body: body1}}

      assert_raise CaseClauseError, fn ->
        Error.handle_error(response1)
      end

      # Missing "msg" field
      body2 = Jason.encode!(%{"code" => error_code_string})
      response2 = {:ok, %{status: status_code, body: body2}}

      assert_raise CaseClauseError, fn ->
        Error.handle_error(response2)
      end
    end

    test "handles JSON body with empty string values" do
      error_code_string = "internal"
      error_code_atom = :internal
      empty_message = ""
      status_code = 500

      body = Jason.encode!(%{"code" => error_code_string, "msg" => empty_message})
      response = {:ok, %{status: status_code, body: body}}

      assert {:error, error} = Error.handle_error(response)

      assert error.code == error_code_atom
      assert error.status_code == status_code
      assert error.msg == empty_message
    end
  end

  describe "handle_error/1 with {:error, reason}" do
    test "handles :connection_closed error" do
      reason = :connection_closed
      expected_code = :unavailable
      expected_status_code = 500
      expected_message = "Connection closed"
      expected_meta = %{}

      response = {:error, %{reason: reason}}

      assert {:error, error} = Error.handle_error(response)

      assert error.code == expected_code
      assert error.status_code == expected_status_code
      assert error.msg == expected_message
      assert error.meta == expected_meta
    end

    test "handles :checkout_timeout error" do
      reason = :checkout_timeout
      expected_code = :deadline_exceeded
      expected_status_code = 500
      expected_message = "Request timed out"
      expected_meta = %{}

      response = {:error, %{reason: reason}}

      assert {:error, error} = Error.handle_error(response)

      assert error.code == expected_code
      assert error.status_code == expected_status_code
      assert error.msg == expected_message
      assert error.meta == expected_meta
    end

    test "handles :econnrefused error" do
      reason = :econnrefused
      expected_code = :unavailable
      expected_status_code = 500
      expected_message = "Connection refused"
      expected_meta = %{}

      response = {:error, %{reason: reason}}

      assert {:error, error} = Error.handle_error(response)

      assert error.code == expected_code
      assert error.status_code == expected_status_code
      assert error.msg == expected_message
      assert error.meta == expected_meta
    end

    test "handles :disconnected error" do
      reason = :disconnected
      expected_code = :unavailable
      expected_status_code = 500
      expected_message = "Disconnected"
      expected_meta = %{}

      response = {:error, %{reason: reason}}

      assert {:error, error} = Error.handle_error(response)

      assert error.code == expected_code
      assert error.status_code == expected_status_code
      assert error.msg == expected_message
      assert error.meta == expected_meta
    end

    test "handles :timeout error" do
      reason = :timeout
      expected_code = :deadline_exceeded
      expected_status_code = 500
      expected_message = "Request timed out"
      expected_meta = %{}

      response = {:error, %{reason: reason}}

      assert {:error, error} = Error.handle_error(response)

      assert error.code == expected_code
      assert error.status_code == expected_status_code
      assert error.msg == expected_message
      assert error.meta == expected_meta
    end

    test "handles :unknown error" do
      reason = :unknown
      expected_code = :unknown
      expected_status_code = 500
      expected_message = "Unknown Internal error"
      expected_meta = %{}

      response = {:error, %{reason: reason}}

      assert {:error, error} = Error.handle_error(response)

      assert error.code == expected_code
      assert error.status_code == expected_status_code
      assert error.msg == expected_message
      assert error.meta == expected_meta
    end
  end
end
