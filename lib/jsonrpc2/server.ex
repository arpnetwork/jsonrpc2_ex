defmodule JSONRPC2.Server do
  alias JSONRPC2.{Misc, Request, Response}

  def new(modules \\ []) do
    server = :ets.new(:rpc_server, [:public, {:read_concurrency, true}])
    register(server, modules)
    server
  end

  def delete(server) do
    :ets.delete(server)
  end

  def register(server, modules) when is_list(modules) do
    Enum.each(modules, fn mod ->
      register(server, mod)
    end)
  end

  def register(server, mod) when is_atom(mod) do
    name = apply(mod, :__name__, [])
    functions = apply(mod, :__functions__, [])
    register(server, name, mod, functions)
  end

  def register(server, name, mod, functions)
      when is_atom(name) and is_atom(mod) and is_list(functions) do
    :ets.insert_new(server, {name, mod, functions})
  end

  def unregister(server, name) when is_atom(name) do
    name =
      if function_exported?(name, :__name__, 0) do
        apply(name, :__name__, [])
      else
        name
      end

    :ets.delete(server, name)
  end

  def apply(server, data) when is_binary(data) do
    case Request.decode(data) do
      {:ok, req} ->
        __MODULE__.apply(server, req)

      reason ->
        Response.error(reason)
    end
  end

  def apply(server, %Request{} = req) do
    if Request.valid?(req) do
      with {mod, fun} <- parse(req.method) do
        res = do_apply(server, mod, fun, req.params)

        unless Request.is_notify(req) do
          id = req.id

          case res do
            {:ok, res} -> Response.result(res, id)
            reason -> Response.error(reason, id)
          end
        end
      else
        reason ->
          Response.error(reason, Request.id(req))
      end
    else
      Response.error(:invalid_request, Request.id(req))
    end
  end

  def modules(server) do
    :ets.select(server, [{{:"$1", :_, :_}, [], [:"$1"]}])
  end

  def functions(server, mod) when is_atom(mod) do
    with [{_, _, functions}] <- :ets.lookup(server, mod), do: functions
  end

  defp do_apply(server, mod, fun, params) do
    with [{_, mod, functions}] <- :ets.lookup(server, mod),
         true <- Enum.member?(functions, fun) do
      params =
        if is_map(params) do
          [Misc.keys_to_existing_atom(params)]
        else
          params
        end

      if function_exported?(mod, fun, length(params)) do
        apply(mod, fun, params)
      else
        :invalid_params
      end
    else
      _ -> :method_not_found
    end
  rescue
    FunctionClauseError -> :invalid_params
    _ -> :internal_error
  end

  defp parse(method) do
    case String.split(method, "_", parts: 2) do
      [mod, fun] ->
        {String.to_existing_atom(mod), Misc.to_function_name(fun)}

      _ ->
        :method_not_found
    end
  rescue
    ArgumentError ->
      :method_not_found
  end
end
