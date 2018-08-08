defmodule JSONRPC2.Misc do
  def strip(term) when is_map(term) do
    term
    |> Map.from_struct()
    |> Stream.reject(&(elem(&1, 1) == :undefined))
    |> Enum.into(%{})
  end

  def keys_to_existing_atom(obj) do
    obj
    |> Stream.map(fn {key, value} ->
      {String.to_existing_atom(key), value}
    end)
    |> Enum.into(%{})
  end

  def to_method_name(mod, name) when is_atom(mod) and is_atom(name) do
    function = name |> Atom.to_string() |> camelize()
    "#{mod}_#{function}"
  end

  def to_function_name(fun) when is_binary(fun) do
    fun |> Macro.underscore() |> String.to_existing_atom()
  end

  def module_name(mod) do
    mod
    |> Module.split()
    |> List.last()
    |> String.downcase()
    |> String.to_atom()
  end

  def unique_id do
    System.unique_integer([:positive]) |> Integer.to_string()
  end

  def camelize(""), do: ""

  def camelize(string) do
    <<ch, rest::binary>> = Macro.camelize(string)
    <<to_lower_char(ch), rest::binary>>
  end

  defp to_lower_char(char) when char >= ?A and char <= ?Z, do: char + 32
  defp to_lower_char(char), do: char
end
