defmodule JSONRPC2 do
  @moduledoc """
  JSON-RPC is a stateless, light-weight remote procedure call (RPC) protocol.
  """

  @version "2.0"

  @spec version() :: String.t()
  def version, do: @version
end
