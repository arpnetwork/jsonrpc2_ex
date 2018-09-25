defmodule JSONRPC2.ObjectTest.Request do
  defstruct method: :undefined, params: :undefined
end

defmodule JSONRPC2.ObjectTest do
  alias JSONRPC2.ObjectTest.Request
  alias JSONRPC2.Object

  use ExUnit.Case
  doctest JSONRPC2.Object

  test "decode" do
    {:ok, req} = Object.decode(~s({"method": "subtract"}), Request)
    assert match?(%Request{}, req)
    assert req.method == "subtract"
    assert req.params == :undefined
  end

  test "encode" do
    assert Object.encode!(%Request{method: "subtract"}) == ~s({"method":"subtract"})
  end
end
