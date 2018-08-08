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

  alias JSONRPC2.Misc
  alias Poison.{ParseError, DecodeError}

  defstruct jsonrpc: :undefined, method: :undefined, params: [], id: :undefined

  def new(method, fields \\ []) when is_binary(method) do
    %__MODULE__{jsonrpc: JSONRPC2.version(), method: method} |> struct!(fields)
  end

  def decode(data) do
    {:ok, decode!(data)}
  rescue
    _exception in [ParseError, DecodeError] ->
      :parse_error
  end

  def decode!(data) do
    Poison.decode!(data, as: %__MODULE__{})
  end

  def encode!(req) do
    unless valid?(req) do
      raise ArgumentError
    end

    req |> Misc.strip() |> Poison.encode!()
  end

  def is_notify(req) do
    valid?(req) && req.id == :undefined
  end

  def valid?(req) do
    req.jsonrpc == JSONRPC2.version() && valid_id?(req.id) && valid_method?(req.method) &&
      valid_params?(req.params)
  end

  def id(req) do
    if is_binary(req.id) || is_integer(req.id), do: req.id
  end

  defp valid_id?(id) do
    id == :undefined || is_binary(id) || is_integer(id)
  end

  defp valid_method?(method) do
    is_binary(method)
  end

  defp valid_params?(params) do
    is_list(params) || is_map(params)
  end
end
