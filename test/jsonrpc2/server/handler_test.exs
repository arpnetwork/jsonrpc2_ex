defmodule JSONRPC2.Server.HandlerTest.Demo do
  use JSONRPC2.Server.Handler

  on request("add", [a, b], context) when is_integer(a) and is_integer(b) do
    c = Map.get(context, :c, 0)
    {:ok, a + b + c}
  end

  on request("hi", [who]) when is_binary(who) do
    IO.puts("Hi #{who}")
  end

  on request("fail") do
    raise ArgumentError
  end
end

defmodule JSONRPC2.Server.HandlerTest do
  alias JSONRPC2.Server.HandlerTest.Demo

  import ExUnit.CaptureIO

  use ExUnit.Case

  test "perform" do
    assert Demo.perform("add", [1, 2], %{c: 3}) == {:ok, 6}

    assert capture_io(fn ->
             assert Demo.perform("hi", ["R"]) == :ok
           end) == "Hi R\n"
  end

  test "perform failed" do
    assert Demo.perform("add", [1]) == {:error, :invalid_params}
    assert Demo.perform("add", [1, "2"]) == {:error, :invalid_params}
  end

  test "compile error" do
    assert_raise CompileError, fn ->
      defmodule CompileErrorDemo do
        use JSONRPC2.Server.Handler

        on norequest("fail") do
        end
      end
    end

    assert_raise CompileError, fn ->
      defmodule CompileErrorDemo do
        use JSONRPC2.Server.Handler

        on request(fail) do
        end
      end
    end
  end
end
