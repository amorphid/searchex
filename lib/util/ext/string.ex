defmodule Util.Ext.String do

  @moduledoc false

  def wordlist(string) do
    string
    |> String.replace(~r/[^A-Za-z0-9]/, " ", global: true)
    |> String.downcase
    |> String.split
  end

  def wordcount(string) do
    string
    |> wordlist
    |> Enum.count
  end

  def wordstems(string) do
    string
    |> wordlist
    |> Enum.map(&StemEx.stem/1)
  end

  def empty?(string) do
    String.length(string) == 0
  end

  def present?(string) do
    ! empty?(string)
  end

  def to_atom(elem) when is_binary(elem), do: String.to_atom(elem)
  def to_atom(elem), do: elem

  def to_chardata(list) when is_list(list), do: list
  def to_chardata(other), do: to_string(other)
end