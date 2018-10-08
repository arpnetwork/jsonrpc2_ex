defmodule JSONRPC2.Object do
  @moduledoc """
  JSON RPC Object.
  """

  alias JSONRPC2.Misc

  @doc """
  Returns `true` if `term` is an `id`; otherwise returns `false`.

  ## Examples

      iex> alias JSONRPC2.Object
      iex> Object.is_id("123")
      true
      iex> Object.is_id(123)
      true
      iex> Object.is_id(:undefined)
      false
  """
  defguard is_id(term) when is_binary(term) or is_integer(term)

  @doc """
  Returns `true` if `term` is a `params`; otherwise returns `false`.

  ## Examples

      iex> alias JSONRPC2.Object
      iex> Object.is_params(["123"])
      true
      iex> Object.is_params(%{name: "123"})
      true
      iex> Object.is_params("123")
      false
  """
  defguard is_params(term) when is_list(term) or is_map(term)

  @doc """
  Decodes a JSON encoded string into the JSON RPC object/objects.
  """
  def decode(data, as) when is_binary(data) do
    case Poison.decode(data) do
      {:ok, value} ->
        if Misc.all?(value, &is_map/1) do
          {:ok, Misc.map(value, &transform(&1, as))}
        else
          {:error, :invalid}
        end

      _ ->
        {:error, :parse_error}
    end
  end

  @doc """
  Encodes the JSON RPC object/objects into a JSON encoded string.
  """
  def encode!(term) do
    term
    |> Misc.map(&strip/1)
    |> Poison.encode!()
  end

  @doc """
  Transforms a map as a JSON RPC object.
  """
  def transform(value, as) when is_map(value) do
    trans = fn {key, default}, acc ->
      value =
        Map.get_lazy(value, Atom.to_string(key), fn ->
          Map.get(value, key, default)
        end)

      Map.put(acc, key, value)
    end

    fields =
      as
      |> struct()
      |> Map.from_struct()
      |> Enum.reduce(%{}, trans)

    struct(as, fields)
  end

  defp strip(%{__struct__: _} = obj) do
    obj
    |> Map.from_struct()
    |> Stream.reject(&(elem(&1, 1) == :undefined))
    |> Enum.into(%{})
  end
end
