defmodule JSONRPC2.Response do
  @moduledoc """
  JSON-RPC 2.0 Response object.

  ## Examples

      iex> alias JSONRPC2.Response
      iex> resp = Response.new(result: [42, 23], id: 1)
      iex> data = Response.encode!(resp)
      ~s({"result":[42,23],"jsonrpc":"2.0","id":1})
      iex> Response.decode(data)
      {:ok, %JSONRPC2.Response{id: 1, jsonrpc: "2.0", result: [42, 23]}}
      iex> Response.error({:method_not_found, "Method not found", %{method: "subtract"}}, 1)
      %JSONRPC2.Response{
        error: %{
          code: -32601,
          data: %{method: "subtract"},
          message: "Method not found"
        },
        id: 1,
        jsonrpc: "2.0",
        result: :undefined
      }
  """

  alias JSONRPC2.{Misc, Object}

  import JSONRPC2.Object, only: :macros

  defstruct jsonrpc: :undefined, result: :undefined, error: :undefined, id: :undefined

  @doc """
  Builds a new `Response` object.
  """
  def new(fields \\ []) do
    %__MODULE__{jsonrpc: JSONRPC2.version()} |> struct!(fields)
  end

  @doc """
  Builds a new `Request` object with given `result`.
  """
  def result(res, id) do
    new(result: res, id: id)
  end

  @doc """
  Builds a new `Request` object with given `error`.
  """
  def error(reason, id \\ nil)

  def error({reason, message, data}, id) do
    error(reason, message, data, id)
  end

  def error({reason, message}, id) do
    error(reason, message, nil, id)
  end

  def error(reason, id) do
    error(reason, nil, nil, id)
  end

  def error(reason, message, data, id) when is_atom(reason) do
    code = reason_to_code(reason)
    message = with nil <- message, do: reason_to_string(reason)
    error(code, message, data, id)
  end

  def error(code, message, data, id) when is_integer(code) do
    message = with nil <- message, do: "Unknown"

    err = %{
      code: code,
      message: message
    }

    err = unless is_nil(data), do: Map.put(err, :data, data), else: err
    new(error: err, id: id)
  end

  @doc """
  Decodes a JSON encoded string into the `Response` object/objects.
  """
  def decode(data) do
    case Object.decode(data, %__MODULE__{}) do
      {:ok, resp} ->
        {:ok, Misc.map(resp, &transform/1)}

      {:error, :invalid} ->
        {:error, :invalid_response}

      error ->
        error
    end
  end

  @doc """
  Encodes the `Response` object/objects into a JSON encoded string.
  """
  defdelegate encode!(resp), to: Object

  @doc """
  Returns true if `resp` is success; otherwise returns false.
  """
  def success?(resp) do
    valid_result?(resp)
  end

  @doc """
  Returns true if `resp` is a valid `Response`; otherwise returns false.
  """
  def valid?(%__MODULE__{} = resp) do
    resp.jsonrpc == JSONRPC2.version() && is_id(resp.id) &&
      (valid_result?(resp) || valid_error?(resp))
  end

  def valid?(_), do: false

  defp transform(resp) do
    if is_map(resp.error) do
      fun = fn {key, value} ->
        if key in ["code", "message"] do
          {String.to_existing_atom(key), value}
        end
      end

      error =
        resp.error
        |> Stream.map(fun)
        |> Stream.reject(&is_nil/1)
        |> Enum.into(%{})

      struct!(resp, error: error)
    else
      resp
    end
  end

  defp valid_result?(resp) do
    resp.result != :undefined && resp.error == :undefined
  end

  defp valid_error?(resp) do
    error = &Map.get(resp.error, &1)

    resp.result == :undefined && is_map(resp.error) && is_integer(error.(:code)) &&
      is_binary(error.(:message))
  end

  defp reason_to_code(reason) when is_atom(reason) do
    case reason do
      :parse_error -> -32700
      :invalid_request -> -32600
      :method_not_found -> -32601
      :invalid_params -> -32602
      :internal_error -> -32603
      :server_error -> -32000
      _ -> -32099
    end
  end

  defp reason_to_string(reason) when is_atom(reason) do
    reason
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end
end
