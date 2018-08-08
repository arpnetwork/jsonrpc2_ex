defmodule JSONRPC2.Client.HTTP do
  alias JSONRPC2.{Misc, Request, Response}

  defmacro __using__(opts) do
    name = Keyword.get_lazy(opts, :name, fn -> Misc.module_name(__CALLER__.module) end)

    quote location: :keep do
      import JSONRPC2.Client.HTTP

      @name unquote(name)
    end
  end

  defmacro defcall(call) do
    define(:call, call)
  end

  defmacro defnotify(call) do
    define(:notify, call)
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

  def call(url, method, params \\ []) when is_binary(method) do
    id = Misc.unique_id()
    Request.new(method, params: params, id: id) |> run(url, id)
  end

  def notify(url, method, params \\ []) when is_binary(method) do
    Request.new(method, params: params) |> run(url)
  end

  defp run(req, url, id \\ nil) do
    data = Request.encode!(req)

    headers = [
      {"Content-Type", "application/json"}
    ]

    with {:ok, status, _headers, body} <- :hackney.post(url, headers, data, [:with_body]),
         :ok <- Plug.Conn.Status.reason_atom(status) do
      unless is_nil(id) do
        case Response.decode(body) do
          {:ok, %Response{id: ^id} = resp} ->
            if Response.success?(resp) do
              {:ok, resp.result}
            else
              {:error, resp.error}
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
end
