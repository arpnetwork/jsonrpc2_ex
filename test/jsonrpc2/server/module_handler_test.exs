defmodule JSONRPC2.Server.ModuleHandlerTest.Demo do
  use JSONRPC2.Server.Module

  def add(a, b) when is_integer(a) and is_integer(b) do
    {:ok, a + b}
  end

  def fail do
    apply(__MODULE__, :add, [1])
  end
end

defmodule JSONRPC2.Server.ModuleHandlerTest do
  alias JSONRPC2.Server.ModuleHandler
  alias JSONRPC2.Server.ModuleHandlerTest.Demo

  use ExUnit.Case

  setup do
    context = ModuleHandler.init([Demo])

    on_exit(fn ->
      ModuleHandler.terminate(context)
    end)

    [context: context]
  end

  test "perform", %{context: context} do
    assert perform("demo_add", [1, 2], context) == {:ok, 3}
  end

  test "perform failed", %{context: context} do
    assert perform("demo_add", [1], context) == {:error, :invalid_params}
    assert perform("demo2_add", [1, 2], context) == {:error, :method_not_found}
  end

  defp perform(method, params, context) do
    ModuleHandler.perform(method, params, context)
  end
end
