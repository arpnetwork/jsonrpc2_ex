defmodule JSONRPC2.ServerTest.Demo do
  use JSONRPC2.Server.Handler

  def add(a, b) do
    {:ok, a + b}
  end

  def fail do
    raise ArgumentError
  end
end

defmodule JSONRPC2.ServerTest do
  alias JSONRPC2.ServerTest.Demo
  alias JSONRPC2.{Request, Response, Server}

  use ExUnit.Case

  import ExUnit.CaptureLog

  setup do
    [server: Server.new([Demo])]
  end

  test "register" do
    server = Server.new()

    assert Server.modules(server) == []
    Server.register(server, Demo)
    assert Server.modules(server) == [:demo]
    assert Server.functions(server, :demo) == [:add, :fail]

    Server.delete(server)
  end

  test "unregister", %{server: server} do
    Server.unregister(server, Demo)
    assert Server.modules(server) == []

    Server.register(server, Demo)
    Server.unregister(server, :demo)
    assert Server.modules(server) == []
  end

  test "apply", %{server: server} do
    req = Request.new("demo_add", params: [1, 2], id: 1)
    resp = Response.result(3, 1)
    assert Server.apply(server, req) == resp

    req = req |> Request.encode!()
    assert Server.apply(server, req) == resp

    req = "[#{req},#{req}]"
    assert Server.apply(server, req) == [resp, resp]
  end

  test "apply failed", %{server: server} do
    req = ""
    assert Server.apply(server, req) == Response.error(:parse_error)

    req = %Request{}
    assert Server.apply(server, req) == Response.error(:invalid_request)

    req = Request.new("demo_add2", id: 1)
    assert Server.apply(server, req) == Response.error(:method_not_found, 1)

    req = Request.new("demo_add", id: 2)
    assert Server.apply(server, req) == Response.error(:invalid_params, 2)

    req = Request.new("demo_fail", id: 3)

    assert capture_log(fn ->
             assert Server.apply(server, req) == Response.error(:internal_error, 3)
           end) =~ "ArgumentError"
  end
end
