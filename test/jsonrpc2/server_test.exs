defmodule JSONRPC2.ServerTest.Demo do
  use JSONRPC2.Server.Handler

  on request("add", [a, b]) do
    {:ok, a + b}
  end

  on request("hi") do
    :ok
  end

  on request("fail") do
    raise ArgumentError
  end

  on request("extra", [], %{extra: extra}) do
    {:ok, extra}
  end
end

defmodule JSONRPC2.ServerTest do
  alias JSONRPC2.ServerTest.Demo
  alias JSONRPC2.{Request, Response, Server}

  use ExUnit.Case

  import ExUnit.CaptureLog

  setup do
    server = Server.new(Demo)

    on_exit(fn ->
      Server.delete(server)
    end)

    [server: server]
  end

  test "perform", %{server: server} do
    req = Request.new("add", params: [1, 2], id: 1)
    resp = Response.result(3, 1)
    assert Server.perform(server, req) == resp

    req = req |> Request.encode!()
    assert Server.perform(server, req) == Response.encode!(resp)

    req = "[#{req},#{req}]"
    assert Server.perform(server, req) == Response.encode!([resp, resp])

    req = Request.new("hi", id: 2)
    assert Server.perform(server, req) == Response.result(nil, 2)
  end

  test "perform extra context", %{server: server} do
    req = Request.new("extra", id: 1)
    assert Server.perform(server, req, %{extra: 3}) == Response.result(3, 1)
  end

  test "perform failed", %{server: server} do
    req = ""
    assert Server.perform(server, req) == Response.encode!(Response.error(:parse_error))

    req = %Request{}
    assert Server.perform(server, req) == Response.error(:invalid_request)

    req = Request.new("add2", id: 1)
    assert Server.perform(server, req) == Response.error(:method_not_found, 1)

    req = Request.new("add", id: 2)
    assert Server.perform(server, req) == Response.error(:invalid_params, 2)

    req = Request.new("fail", id: 3)

    assert capture_log(fn ->
             assert Server.perform(server, req) == Response.error(:internal_error, 3)
           end) =~ "ArgumentError"
  end
end
