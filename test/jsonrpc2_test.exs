defmodule JSONRPC2Test do
  use ExUnit.Case
  doctest JSONRPC2

  test "version" do
    assert JSONRPC2.version() == "2.0"
  end
end
