defmodule JSONRPC2.Server.Handler do
  @moduledoc """
  JSON RPC Server handler.
  """

  defmacro __using__(_opts) do
    quote location: :keep do
      import JSONRPC2.Server.Handler

      @before_compile JSONRPC2.Server.Handler

      @methods []

      def init(opts) when is_map(opts) do
        opts
      end

      def terminate(_context) do
      end

      defoverridable init: 1, terminate: 1
    end
  end

  defmacro __before_compile__(env) do
    default_handle_request =
      if not Module.defines?(env.module, {:handle_request, 3}, :defp) do
        quote location: :keep do
          defp handle_request(_method, _params, _context) do
            {:error, :method_not_found}
          end
        end
      else
        quote do
        end
      end

    quote location: :keep do
      unquote(default_handle_request)

      def perform(method, params, context \\ %{}) do
        handle_request(method, params, context)
      rescue
        e in FunctionClauseError ->
          if match?(
               %FunctionClauseError{module: __MODULE__, function: :handle_request, arity: 3},
               e
             ) do
            if Enum.member?(@methods, method) do
              {:error, :invalid_params}
            else
              {:error, :method_not_found}
            end
          else
            reraise(e, System.stacktrace())
          end
      end
    end
  end

  defmacro on(call, expr) do
    vars = &List.duplicate(Macro.var(:_, nil), &1)

    fun = fn
      {:request, meta, [method | _] = args}, nil ->
        {{:handle_request, meta, args ++ vars.(3 - length(args))}, method}

      other, method ->
        {other, method}
    end

    case Macro.postwalk(call, nil, fun) do
      {call, method} when is_binary(method) ->
        quote do
          @methods [unquote(method) | @methods]

          defp unquote(call), unquote(expr)
        end

      _ ->
        raise CompileError
    end
  end
end
