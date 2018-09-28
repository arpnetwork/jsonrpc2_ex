defmodule JSONRPC2.Server.ModuleHandler do
  @moduledoc """
  JSON RPC Server module handler.
  """

  alias JSONRPC2.Misc

  use JSONRPC2.Server.Handler

  def init(modules) do
    modules =
      modules
      |> Stream.map(fn mod ->
        name = apply(mod, :__name__, [])
        {name, mod}
      end)
      |> Enum.into(%{})

    %{modules: modules}
  end

  defp handle_request(method, params, %{modules: modules} = context) do
    case parse(method) do
      {mod, fun} ->
        case Map.fetch(modules, mod) do
          {:ok, mod} ->
            context =
              context
              |> Map.delete(:modules)
              |> Map.put(:method, method)

            apply(mod, :__perform__, [fun, params, context])

          _ ->
            {:error, :method_not_found}
        end

      reason ->
        {:error, reason}
    end
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
