defmodule JSONRPC2.Server.Plug do
  @moduledoc """
  JSON RPC Server for Plug.
  """

  alias JSONRPC2.{Response, Server}
  alias Plug.Conn.{Status, Utils}

  import JSONRPC2.Misc, only: :macros
  import Plug.Conn

  @doc false
  def init(opts) do
    {modules, opts} = Keyword.pop(opts, :modules, [])
    Keyword.put(opts, :rpc, Server.new(modules))
  end

  @doc false
  def call(conn, opts) do
    with "POST" <- conn.method,
         "/" <- conn.request_path,
         {_, type} when is_binary(type) <- List.keyfind(conn.req_headers, "content-type", 0),
         {:ok, "application", "json", _} <- Utils.media_type(type),
         {:ok, body, conn} <- read_body(conn) do
      Process.put(:remote_ip, conn.remote_ip)

      server = Keyword.fetch!(opts, :rpc)

      case Server.apply(server, body) do
        %Response{} = resp ->
          send_rpc_resp(conn, resp)

        resps when is_nonempty_list(resps) ->
          send_rpc_resp(conn, resps)

        _ ->
          send_resp(conn, :ok, "")
      end
    else
      _ -> send_resp(conn, :bad_request)
    end
  end

  defp send_rpc_resp(conn, resp) do
    data = Response.encode!(resp)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(:ok, data)
  end

  defp send_resp(conn, status) when is_atom(status) do
    send_resp(conn, Status.code(status))
  end

  defp send_resp(conn, status) when is_integer(status) do
    send_resp(conn, status, Status.reason_phrase(status))
  end
end
