defmodule Searchex.Command.Results do
  @moduledoc false

#  use ExMake

  # error checks:
  # - valid cfg_name
  # - existing cfg_name
  # - valid cfg
  def exec do
    Searchex.Command.Search.Cache.read_results
  end

  def handle_chain(_cfg_name) do
    "TBD"
  end
end
