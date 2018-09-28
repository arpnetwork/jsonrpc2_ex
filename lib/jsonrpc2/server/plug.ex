defmodule JSONRPC2.Server.Plug do
  @moduledoc """
  JSON RPC Server for Plug.
  """

  alias JSONRPC2.Server
  alias Plug.Conn.{Status, Utils}

  import Plug.Conn

  @doc false
  def init({module, opts}) do
    [rpc: Server.new(module, opts)]
  end

  def init(module) when is_atom(module) do
    [rpc: Server.new(module)]
  end

  @doc false
  def call(conn, opts) do
    with "POST" <- conn.method,
         "/" <- conn.request_path,
         {_, type} when is_binary(type) <- List.keyfind(conn.req_headers, "content-type", 0),
         {:ok, "application", "json", _} <- Utils.media_type(type),
         {:ok, body, conn} <- read_body(conn) do
      server = Keyword.fetch!(opts, :rpc)

      resp = Server.perform(server, body, %{remote_ip: conn.remote_ip})
      send_rpc_resp(conn, resp)
    else
      _ -> send_resp(conn, :bad_request)
    end
  end

  defp send_rpc_resp(conn, resp) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(:ok, resp)
  end

  defp send_resp(conn, status) when is_atom(status) do
    send_resp(conn, Status.code(status))
  end

  defp send_resp(conn, status) when is_integer(status) do
    send_resp(conn, status, Status.reason_phrase(status))
  end
end
