defmodule JSONRPC2.ResponseTest do
  alias JSONRPC2.Response

  use ExUnit.Case
  doctest JSONRPC2.Response

  test "reason_to_code" do
    [
      parse_error: -32700,
      invalid_request: -32600,
      method_not_found: -32601,
      invalid_params: -32602,
      internal_error: -32603,
      server_error: -32000,
      other: -32099
    ]
    |> Enum.each(fn {reason, code} ->
      assert Response.reason_to_code(reason) == code
    end)
  end
end
