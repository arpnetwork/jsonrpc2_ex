defmodule JSONRPC2.Client.HTTP do
  @moduledoc """
  A JSON RPC HTTP Client.
  """

  alias JSONRPC2.{Misc, Request, Response}

  import JSONRPC2.Misc, only: :macros

  defmacro __using__(opts) do
    name = Keyword.get_lazy(opts, :name, fn -> Misc.module_name(__CALLER__.module) end)

    quote location: :keep do
      import JSONRPC2.Client.HTTP

      @name unquote(name)
    end
  end

  @doc """
  Defines a JSON RPC call with the given name and body.
  """
  defmacro defcall(call) do
    define(:call, call)
  end

  @doc """
  Defines a JSON RPC notify with the given name and body.
  """
  defmacro defnotify(call) do
    define(:notify, call)
  end

  @doc """
  Makes a synchronous call to the JSON RPC server and waits for its reply.
  """
  def call(url, method, params \\ :undefind) do
    build({:call, method, params}) |> run(url)
  end

  @doc """
  Makes a synchronous notify to the JSON RPC server.
  """
  def notify(url, method, params \\ :undefined) do
    build({:notify, method, params}) |> run(url)
  end

  @doc """
  Makes a batch synchronous call/notify to the JSON RPC server and waits for its reply.
  """
  def batch(url, reqs) when is_nonempty_list(reqs) do
    reqs
    |> Enum.map(&build/1)
    |> run(url)
  end

  defp define(type, {name, meta, args}) do
    args = with nil <- args, do: []
    url = Macro.var(:url, nil)
    call = {name, meta, [url | args]}
    args = with [{:%{}, _, _} = named_params] <- args, do: named_params

    quote location: :keep do
      def unquote(call) do
        method = Misc.to_method_name(@name, unquote(name))
        unquote(type)(unquote(url), method, unquote(args))
      end
    end
  end

  defp run(req, url) do
    unless Misc.all?(req, &Request.valid?/1) do
      raise ArgumentError
    end

    data = Request.encode!(req)

    id =
      cond do
        is_list(req) ->
          req
          |> Enum.map(&Request.id/1)
          |> Enum.reject(&is_nil/1)

        true ->
          Request.id(req)
      end

    headers = [
      {"Content-Type", "application/json"}
    ]

    with {:ok, status, _headers, body} <- :hackney.post(url, headers, data, [:with_body]),
         :ok <- Plug.Conn.Status.reason_atom(status) do
      unless Misc.blank?(id) do
        with {:ok, resp} <- Response.decode(body) do
          if Misc.all?(resp, &Response.valid?/1) do
            transform(resp, id)
          else
            {:error, :invalid_response}
          end
        end
      else
        :ok
      end
    else
      reason when is_atom(reason) ->
        {:error, reason}

      reason ->
        reason
    end
  end

  defp transform(resps, ids) when is_nonempty_list(resps) do
    if resps |> Enum.map(& &1.id) |> Enum.sort() == ids do
      resps
      |> Enum.sort_by(& &1.id)
      |> Enum.map(&transform(&1, &1.id))
    else
      {:error, :invalid}
    end
  end

  defp transform(%Response{id: id} = resp, id) do
    if Response.success?(resp) do
      {:ok, resp.result}
    else
      {:error, resp.error}
    end
  end

  defp transform(_resp, _id) do
    {:error, :invalid}
  end

  defp build({:call, method}) do
    build({:call, method, :undefined})
  end

  defp build({:call, method, params}) do
    Request.new(method, params: params, id: Misc.unique_id())
  end

  defp build({:notify, method}) do
    build({:notify, method, :undefined})
  end

  defp build({:notify, method, params}) do
    Request.new(method, params: params)
  end
end
