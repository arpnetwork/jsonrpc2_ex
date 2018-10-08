defmodule JSONRPC2.Misc do
  @moduledoc """
  JSON RPC Misc.
  """

  @doc """
  Returns true if term is a list with one or more elements; otherwise returns false.

  ## Examples

      iex> import JSONRPC2.Misc
      iex> is_nonempty_list([1])
      true
      iex> is_nonempty_list([])
      false
  """
  defguard is_nonempty_list(term) when is_list(term) and length(term) > 0

  @doc """
  Converts the map's string key to existing atom.

  ## Examples

      iex> JSONRPC2.Misc.keys_to_existing_atom(%{"id" => 1, "method" => "subtract"})
      %{id: 1, method: "subtract"}
  """
  def keys_to_existing_atom(obj) do
    obj
    |> Stream.map(fn {key, value} ->
      {String.to_existing_atom(key), value}
    end)
    |> Enum.into(%{})
  end

  @doc """
  Makes a JSON RPC method name by given `mod` and `name`.

  ## Examples

      iex> JSONRPC2.Misc.to_method_name(:demo, :to_method_name)
      "demo_toMethodName"
  """
  def to_method_name(mod, name) when is_atom(mod) and is_atom(name) do
    function = name |> Atom.to_string() |> camelize()
    "#{mod}_#{function}"
  end

  @doc """
  Converts CamelCase format function name to the atom version.

  ## Examples

    iex> JSONRPC2.Misc.to_function_name("toFunctionName")
    :to_function_name
  """
  def to_function_name(fun) when is_binary(fun) do
    fun |> Macro.underscore() |> String.to_existing_atom()
  end

  @doc """
  Converts module to a short name.

  ## Examples

      iex> JSONRPC2.Misc.module_name(JSONRPC2.Misc)
      :misc
  """
  def module_name(mod) do
    mod
    |> Module.split()
    |> List.last()
    |> String.downcase()
    |> String.to_atom()
  end

  @doc """
  Converts the given string to CamelCase format.

  ## Examples

      iex> JSONRPC2.Misc.camelize("say_hi")
      "sayHi"
  """
  def camelize(""), do: ""

  def camelize(string) do
    <<ch, rest::binary>> = Macro.camelize(string)
    <<to_lower_char(ch), rest::binary>>
  end

  @doc """
  Converts an atom `reason` to readable string.

  ## Examples

      iex> JSONRPC2.Misc.reason_to_string(:method_not_found)
      "Method not found"
  """
  def reason_to_string(reason) when is_atom(reason) do
    reason
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  @doc """
  Determines if the value is blank.
  """
  def blank?(nil), do: true
  def blank?([]), do: true
  def blank?(<<>>), do: true
  def blank?(_), do: false

  @doc false
  def map(term, fun), do: enum(term, fun, &Enum.map/2)

  @doc false
  def all?(term, fun), do: enum(term, fun, &Enum.all?/2)

  defp enum(term, fun, enum_fun) when is_nonempty_list(term), do: apply(enum_fun, [term, fun])
  defp enum(term, fun, _), do: fun.(term)

  defp to_lower_char(char) when char >= ?A and char <= ?Z, do: char + 32
end
