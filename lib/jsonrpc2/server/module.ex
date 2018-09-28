defmodule JSONRPC2.Server.Module do
  @moduledoc """
  JSON RPC Server Module.
  """

  alias JSONRPC2.Misc

  defmacro __using__(opts) do
    name = Keyword.get_lazy(opts, :name, fn -> Misc.module_name(__CALLER__.module) end)
    only = Keyword.get(opts, :only)
    except = Keyword.get(opts, :except)

    quote do
      import JSONRPC2.Server.Module

      @before_compile JSONRPC2.Server.Module

      @name unquote(name)
      @only unquote(only)
      @except unquote(except)
    end
  end

  defmacro __before_compile__(env) do
    mod = env.module

    functions = exported_functions(mod)

    quote location: :keep do
      def __name__, do: @name

      def __functions__, do: unquote(functions)

      unless Module.defines?(unquote(mod), {:__before_perform__, 3}) do
        defp __before_perform__(_name, args, _context) do
          {:ok, args}
        end
      end

      def __perform__(name, args, context) do
        if name in unquote(functions) do
          with {:ok, args} <- __before_perform__(name, args, context) do
            apply(__MODULE__, name, args)
          end
        else
          {:error, :method_not_found}
        end
      rescue
        e in [FunctionClauseError, UndefinedFunctionError] ->
          if match?(%{module: __MODULE__, function: ^name}, e) do
            {:error, :invalid_params}
          else
            reraise(e, System.stacktrace())
          end
      end
    end
  end

  defmacro before_perform(method, params, context, do: block) do
    quote location: :keep do
      defp __before_perform__(unquote(method), unquote(params), unquote(context)) do
        unquote(block)
      end
    end
  end

  defp exported_functions(mod) do
    functions =
      mod
      |> Module.definitions_in(:def)
      |> Keyword.keys()

    get_functions = fn key ->
      mod
      |> Module.get_attribute(key)
      |> check_functions(functions)
    end

    only = get_functions.(:only)
    except = get_functions.(:except)

    cond do
      not is_nil(only) -> only
      not is_nil(except) -> functions -- except
      true -> functions
    end
  end

  defp check_functions(nil, _), do: nil

  defp check_functions(list, functions) when is_list(list) do
    assert(list == Enum.uniq(list))

    Enum.each(list, fn fun ->
      assert(is_atom(fun) && Enum.member?(functions, fun))
    end)

    list
  end

  defp assert(expression) do
    unless expression, do: raise(CompileError)
  end
end
