defmodule JSONRPC2.ResponseTest do
  alias JSONRPC2.Response

  use ExUnit.Case
  doctest JSONRPC2.Response

  test "reason_to_code" do
    [
      parse_error: -32_700,
      invalid_request: -32_600,
      method_not_found: -32_601,
      invalid_params: -32_602,
      internal_error: -32_603,
      server_error: -32_000,
      other: -32_099
    ]
    |> Enum.each(fn {reason, code} ->
      assert Response.reason_to_code(reason) == code
    end)
  end
end
