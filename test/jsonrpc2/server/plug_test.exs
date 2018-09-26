defmodule JSONRPC2.PlugTest do
  use ExUnit.Case

  setup_all do
    alias Plug.Adapters.Cowboy2

    port = 3000

    {:ok, _} = Cowboy2.http(JSONRPC2.Server.Plug, [], port: port)

    on_exit(fn ->
      Cowboy2.shutdown(JSONRPC2.Server.Plug.HTTP)
    end)

    [url: "http://127.0.0.1:#{port}/"]
  end

  test "request", %{url: url} do
    req = ~s({"jsonrpc": "2.0", "method": "subtract", "id": 1})
    assert post(url, req) == :ok

    batch = "[#{req},#{req}]"
    assert post(url, batch) == :ok

    notify = ~s({"jsonrpc": "2.0", "method": "subtract"})
    assert post(url, notify) == :ok
  end

  test "bad request", %{url: url} do
    data = "{}"
    assert post(url <> "api", data) == :bad_request
    assert post(url, data, []) == :bad_request
  end

  defp post(url, data, headers \\ nil) do
    headers = with nil <- headers, do: [{"Content-Type", "application/json"}]

    {:ok, status, _, _} = :hackney.post(url, headers, data, [:with_body])
    Plug.Conn.Status.reason_atom(status)
  end
end
