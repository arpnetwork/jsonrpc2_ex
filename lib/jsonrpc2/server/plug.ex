defmodule JSONRPC2.Server.Plug do
  import Plug.Conn

  alias JSONRPC2.{Response, Server}
  alias Plug.Conn.Status

  def init(opts) do
    {modules, opts} = Keyword.pop(opts, :modules, [])
    Keyword.put(opts, :rpc, Server.new(modules))
  end

  def call(conn, opts) do
    with "POST" <- conn.method,
         "/" <- conn.request_path,
         {_, "application/json"} <- List.keyfind(conn.req_headers, "content-type", 0),
         {:ok, body, conn} <- read_body(conn) do
      case Keyword.fetch!(opts, :rpc) |> Server.apply(body) do
        %Response{} = resp ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(:ok, Response.encode!(resp))

        _ ->
          send_resp(conn, :ok, "")
      end
    else
      _ -> send_resp(conn, :bad_request)
    end
  end

  defp send_resp(conn, status) when is_atom(status) do
    send_resp(conn, Status.code(status))
  end

  defp send_resp(conn, status) when is_integer(status) do
    send_resp(conn, status, Status.reason_phrase(status))
  end
end
