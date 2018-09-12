defmodule JSONRPC2.Request do
  @moduledoc """
  JSON-RPC 2.0 Request object.

  ## Examples

      iex> alias JSONRPC2.Request
      iex> req = Request.new("subtract", params: [42, 23], id: 1)
      iex> data = Request.encode!(req)
      ~s({"params":[42,23],"method":"subtract","jsonrpc":"2.0","id":1})
      iex> Request.decode(data)
      {:ok, %JSONRPC2.Request{id: 1, jsonrpc: "2.0", method: "subtract", params: [42, 23]}}
  """

  alias JSONRPC2.Object

  import JSONRPC2.Object, only: :macros

  defstruct jsonrpc: :undefined, method: :undefined, params: :undefined, id: :undefined

  @doc """
  Builds a new `Request` object.
  """
  def new(method, fields \\ []) when is_binary(method) do
    %__MODULE__{jsonrpc: JSONRPC2.version(), method: method} |> struct!(fields)
  end

  @doc """
  Decodes a JSON encoded string into the `Request` object/objects.
  """
  def decode(data) do
    with {:error, :invalid} <- Object.decode(data, %__MODULE__{}) do
      {:error, :invalid_request}
    end
  end

  @doc """
  Encodes the `Request` object/objects into a JSON encoded string.
  """
  defdelegate encode!(resp), to: Object

  @doc """
  Returns the `id` of `Request` object.
  """
  def id(req) do
    if is_id(req.id), do: req.id
  end

  @doc """
  Returns true if `req` is a notify `Request` object; otherwise returns false.
  """
  def is_notify(req) do
    valid?(req) && req.id == :undefined
  end

  @doc """
  Returns true if `req` is a valid `Request`; otherwise returns false.
  """
  def valid?(%__MODULE__{} = req) do
    req.jsonrpc == JSONRPC2.version() && valid_id?(req.id) && is_binary(req.method) &&
      valid_params?(req.params)
  end

  def valid?(_), do: false

  defp valid_id?(id) do
    id == :undefined || is_id(id)
  end

  defp valid_params?(params) do
    params == :undefined || is_params(params)
  end
end
