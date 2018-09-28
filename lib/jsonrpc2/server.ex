defmodule JSONRPC2.Server do
  @moduledoc """
  A JSON RPC Server.
  """

  alias JSONRPC2.{Misc, Request, Response}

  require Logger

  @doc """
  Builds a new JSON RPC Server.
  """
  def new(module, opts \\ %{}) do
    {module, apply(module, :init, [opts])}
  end

  @doc """
  Deletes the `server`.
  """
  def delete({mod, context}) do
    apply(mod, :terminate, [context])
  end

  def perform(server, data, extra \\ %{})

  @doc """
  Applies the JSON RPC request/requests encoded string to server.
  """
  def perform(server, data, extra) when is_binary(data) do
    res =
      case Request.decode(data) do
        {:ok, req} ->
          resp =
            req
            |> Misc.map(&perform(server, &1, extra))

          with [_ | _] <- resp do
            Enum.reject(resp, &is_nil/1)
          end

        {:error, reason} ->
          Response.error(reason)
      end

    if not Misc.blank?(res) do
      Response.encode!(res)
    else
      ""
    end
  end

  @doc """
  Applies the JSON RPC request to server.
  """
  def perform({module, context}, %Request{} = req, extra) do
    if Request.valid?(req) do
      params = Request.params(req)
      context = Map.merge(context, extra)

      res =
        try do
          apply(module, :perform, [req.method, params, context])
        rescue
          error ->
            Logger.warn(fn ->
              {stacktrace, _} =
                System.stacktrace()
                |> Enum.split_while(&(elem(&1, 0) != __MODULE__))

              Exception.format(:error, error, stacktrace)
            end)

            {:error, :internal_error}
        end

      unless Request.is_notify(req) do
        id = req.id

        case res do
          {:ok, res} -> Response.result(res, id)
          {:error, reason} -> Response.error(reason, id)
          :ok -> Response.result(nil, id)
        end
      end
    else
      Response.error(:invalid_request, Request.id(req))
    end
  end
end
