defmodule JSONRPC2.Server.Handler do
  alias JSONRPC2.Misc

  defmacro __using__(opts) do
    name = Keyword.get_lazy(opts, :name, fn -> Misc.module_name(__CALLER__.module) end)

    quote do
      import JSONRPC2.Server.Handler

      @before_compile JSONRPC2.Server.Handler

      @name unquote(name)
    end
  end

  defmacro __before_compile__(env) do
    mod = env.module
    functions = Module.definitions_in(mod) |> Keyword.keys()

    quote do
      def __name__, do: @name

      def __functions__, do: unquote(functions)
    end
  end

  defmacro method do
    mod = Module.get_attribute(__CALLER__.module, :name)
    fun = elem(__CALLER__.function, 0)
    name = Misc.to_method_name(mod, fun)

    quote do
      unquote(name)
    end
  end
end
