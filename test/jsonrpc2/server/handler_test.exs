defmodule JSONRPC2.Server.HandlerTest.Demo1Server do
  use JSONRPC2.Server.Handler, name: :demo1

  def add(a, b) do
    {:ok, a + b}
  end

  def method_name do
    method()
  end
end

defmodule JSONRPC2.Server.HandlerTest.Demo2Server do
  use JSONRPC2.Server.Handler, only: [:add]

  def add(a, b) do
    {:ok, a + b}
  end

  def fail do
    :ok
  end
end

defmodule JSONRPC2.Server.HandlerTest.Demo3Server do
  use JSONRPC2.Server.Handler, except: [:fail]

  def add(a, b) do
    {:ok, a + b}
  end

  def fail do
    :ok
  end
end

defmodule JSONRPC2.Server.HandlerTest do
  alias JSONRPC2.Server.HandlerTest.{Demo1Server, Demo2Server, Demo3Server}

  use ExUnit.Case

  test "handler" do
    assert Demo1Server.__name__() == :demo1
    assert Demo1Server.__functions__() == [:add, :method_name]
    assert Demo2Server.__functions__() == [:add]
    assert Demo3Server.__functions__() == [:add]

    assert Demo1Server.method_name() == "demo1_methodName"
  end
end
