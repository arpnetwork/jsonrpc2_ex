defmodule JSONRPC2.Server.ModuleTest.Demo1Server do
  use JSONRPC2.Server.Module, name: :demo1

  def add(a, b) when is_integer(a) and is_integer(b) do
    {:ok, a + b}
  end

  def fail do
    apply(__MODULE__, :add, [1])
  end
end

defmodule JSONRPC2.Server.ModuleTest.Demo2Server do
  use JSONRPC2.Server.Module, only: [:add]

  def add(_a, _b) do
  end

  def fail do
  end
end

defmodule JSONRPC2.Server.ModuleTest.Demo3Server do
  use JSONRPC2.Server.Module, except: [:fail]

  def add(_a, _b) do
  end

  def fail do
  end
end

defmodule JSONRPC2.Server.ModuleTest.Demo4Server do
  use JSONRPC2.Server.Module

  before_perform(method, params, _context) do
    {sign, params} = List.pop_at(params, -1)

    if Enum.join([method | params], "_") == sign do
      {:ok, params}
    else
      {:error, :invalid_params}
    end
  end

  def add(a, b) do
    {:ok, a + b}
  end
end

defmodule JSONRPC2.Server.ModuleTest do
  alias JSONRPC2.Server.ModuleTest.{Demo1Server, Demo2Server, Demo3Server, Demo4Server}

  use ExUnit.Case

  test "name & functions" do
    assert Demo1Server.__name__() == :demo1
    assert Demo1Server.__functions__() == [:add, :fail]
    assert Demo2Server.__functions__() == [:add]
    assert Demo3Server.__functions__() == [:add]
  end

  test "perform" do
    assert Demo1Server.__perform__(:add, [1, 2], %{}) == {:ok, 3}
  end

  test "perform failed" do
    perform = &Demo1Server.__perform__(&1, &2, %{})

    assert perform.(:add, [1]) == {:error, :invalid_params}
    assert perform.(:add, [1, "2"]) == {:error, :invalid_params}
    assert perform.(:subtract, [2, 1]) == {:error, :method_not_found}

    assert_raise UndefinedFunctionError, fn ->
      perform.(:fail, [])
    end

    assert Demo2Server.__perform__(:fail, [], %{}) == {:error, :method_not_found}
  end

  test "before_perform" do
    perform = &Demo4Server.__perform__(&1, &2, %{})

    assert perform.(:add, [1, 2, "add_1_2"]) == {:ok, 3}
    assert perform.(:add, [1, 3, "add_1_2"]) == {:error, :invalid_params}
  end
end
