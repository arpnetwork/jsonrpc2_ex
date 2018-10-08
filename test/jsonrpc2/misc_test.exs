defmodule JSONRPC2.MiscTest do
  alias JSONRPC2.Misc

  use ExUnit.Case
  doctest JSONRPC2.Misc

  test "map & all?" do
    to_s = fn v ->
      Misc.map(v, &Integer.to_string/1)
    end

    assert to_s.(1) == "1"
    assert to_s.([1, 2]) == ["1", "2"]

    assert_raise ArgumentError, fn ->
      to_s.([1, [2]])
    end

    is_int = fn v ->
      Misc.all?(v, &is_integer/1)
    end

    assert is_int.(1) == true
    assert is_int.([1, 2]) == true
    assert is_int.([1, "2"]) == false
  end
end
