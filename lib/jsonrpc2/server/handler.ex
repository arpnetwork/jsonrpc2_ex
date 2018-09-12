defmodule JSONRPC2.Server.Handler do
  @moduledoc """
  JSON RPC Server handler.
  """

  alias JSONRPC2.Misc

  defmacro __using__(opts) do
    name = Keyword.get_lazy(opts, :name, fn -> Misc.module_name(__CALLER__.module) end)
    only = Keyword.get(opts, :only)
    except = Keyword.get(opts, :except)

    quote do
      import JSONRPC2.Server.Handler

      @before_compile JSONRPC2.Server.Handler

      @name unquote(name)
      @only unquote(only)
      @except unquote(except)
    end
  end

  defmacro __before_compile__(env) do
    mod = env.module

    functions = Module.definitions_in(mod) |> Keyword.keys()
    only = Module.get_attribute(mod, :only) |> check_functions(functions)
    except = Module.get_attribute(mod, :except) |> check_functions(functions)

    functions =
      cond do
        not is_nil(only) -> only
        not is_nil(except) -> functions -- except
        true -> functions
      end

    quote do
      def __name__, do: @name

      def __functions__, do: unquote(functions)
    end
  end

  @doc """
  Returns current JSON RPC method name.
  """
  defmacro method do
    mod = Module.get_attribute(__CALLER__.module, :name)
    fun = elem(__CALLER__.function, 0)
    name = Misc.to_method_name(mod, fun)

    quote do
      unquote(name)
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
