defmodule JSONRPC2.Client.HTTPTest.DemoServer do
  use JSONRPC2.Server.Module, name: :demo, only: [:add, :hello, :hi]

  def add(a, b) do
    {:ok, a + b}
  end

  def hello(%{name: who}) do
    "Hello, #{who}"
  end

  def hi do
    {:ok, "Hi"}
  end

  def fail do
    :ok
  end
end

defmodule JSONRPC2.Client.HTTPTest.Demo do
  use JSONRPC2.Client.HTTP

  defcall add(a, b)

  defnotify hello(who)

  defcall hi()

  defcall fail()
end

defmodule JSONRPC2.Client.HTTPTest do
  alias JSONRPC2.Client.HTTP
  alias JSONRPC2.Client.HTTPTest.{Demo, DemoServer}
  alias JSONRPC2.Server.ModuleHandler

  use ExUnit.Case
  doctest JSONRPC2.Client.HTTP

  setup_all do
    alias Plug.Adapters.Cowboy2

    {:ok, _} = Cowboy2.http(JSONRPC2.Server.Plug, {ModuleHandler, [DemoServer]}, port: 0)
    ref = JSONRPC2.Server.Plug.HTTP
    port = :ranch.get_port(ref)

    on_exit(fn ->
      Cowboy2.shutdown(ref)
    end)

    [url: "http://127.0.0.1:#{port}/"]
  end

  test "call", %{url: url} do
    assert HTTP.call(url, "demo_hi") == {:ok, "Hi"}

    assert Demo.add(url, 1, 2) == {:ok, 3}
  end

  test "notify", %{url: url} do
    assert HTTP.notify(url, "demo_hi") == :ok

    assert Demo.hello(url, %{name: "John"}) == :ok
  end

  test "batch", %{url: url} do
    require Demo

    reqs = [
      {:call, "demo_hi"},
      {:notify, "demo_hi"}
    ]

    assert HTTP.batch(url, reqs) == [{:ok, "Hi"}]

    res =
      Demo.batch url do
        hello("John")
        add(1, 2)
        add(2, 3)
      end

    assert res == [{:ok, 3}, {:ok, 5}]
  end

  test "invalid request", %{url: url} do
    assert_raise ArgumentError, fn ->
      HTTP.call(url, "", 1)
    end
  end

  test "error response", %{url: url} do
    assert_raise JSONRPC2.Client.HTTPError, fn ->
      Demo.fail!("http://127.0.0.1:1234/")
    end

    assert_raise JSONRPC2.Client.HTTPError, fn ->
      Demo.fail!(url)
    end
  end
end
