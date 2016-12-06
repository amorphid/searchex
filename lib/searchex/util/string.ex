defmodule Searchex.Util.String do

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

  def digest(string, length \\ 5) do
    :crypto.hash(:sha, string)
    |> Base.encode16
    |> String.slice(0,length)
    |> String.downcase
  end

  def empty?(string) do
    String.length(string) == 0
  end

  def present?(string) do
    ! empty?(string)
  end
end
