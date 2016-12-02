defmodule Searchex.Command.Build.Catalog do

  @moduledoc false

  @scan %Searchex.Command.Build.Catalog.Scan{}

  def create_from_scan(scan) do
    scan.params.doc_dirs
    |> Searchex.Util.File.ls_r(scan.params.file_types)
    |> Enum.reduce(scan, fn(file, acc) -> create_from_scan(acc, file) end)
  end

  def create_from_scan(scan, filename) do
    %{scan | input_filename: filename, rawdata: "", docsep_positions: [], docsep_offsets: []}
    |> read_rawdata
    |> gen_docsep_positions
    |> gen_docsep_offsets
    |> gen_docs
    |> extract_counts
    |> extract_fields
  end

  def read_rawdata(scan) do
    %Searchex.Command.Build.Catalog.Scan{scan | rawdata: File.read!(scan.input_filename)}
  end

  def gen_docsep_positions(scan) do
    positions = scan.params.docsep
                |> Regex.scan(scan.rawdata, return: :index )
                |> Enum.map(fn(x) -> [{beg, fin} | _tail] = x; beg + fin end)
    %Searchex.Command.Build.Catalog.Scan{scan | docsep_positions: positions}
  end

  def gen_docsep_offsets(scan) do
    offsets = scan.docsep_positions
              |> gen_offsets([])
    %Searchex.Command.Build.Catalog.Scan{scan | docsep_offsets: offsets}
  end

  def gen_offsets([], list), do: list
  def gen_offsets([head|tail], list) do
    gen_offsets(tail, list ++ [head - Enum.sum(list)])
  end

  def extract_counts(scan) do
    wordcounts = Enum.map(scan.docs, fn(doc) -> doc.wordcount end)
    newvals    = %{numdocs: Enum.count(wordcounts), avg_wordcount: Searchex.Util.Enum.average(wordcounts)}
    Map.merge(scan, newvals)
  end

  def gen_docs(scan) do
    positions = scan.docsep_positions
    offsets   = scan.docsep_offsets
    pairs     = List.zip([positions, offsets])
    gen_docs(scan, scan.rawdata, pairs)
  end
  def gen_docs(scan, _string, []), do: scan
  def gen_docs(scan, string, [{position, offset}|pair_tail]) do
    {string_head, string_tail} = String.split_at(string, offset)
    doc = %Searchex.Command.Build.Catalog.Scan.Doc{
      filename: scan.input_filename,
      docstart: position,
      doclength: String.length(string_head),
      wordcount: Searchex.Util.String.wordcount(string_head),
      wordstems: Searchex.Util.String.wordstems(string_head),
      docid: Searchex.Util.String.signature(string_head),
      body: string_head
    }
    new_scan = Searchex.Command.Build.Catalog.Scan.add_doc(scan, doc)
    gen_docs(new_scan, string_tail, pair_tail)
  end

  def extract_fields(scan) do
    docs  = scan.docs
    new_docs = Enum.map(docs, fn(doc) -> extract_doc_fields(scan, doc) end)
    %Searchex.Command.Build.Catalog.Scan{scan | docs: new_docs}
  end

  def extract_doc_fields(scan, doc) do
    new_fields = Enum.map scan.params.field_defs, fn({field_name, _field_spec}) ->
      {field_name, extract_doc_field(scan, doc, field_name)}
    end
    new_map = Enum.into(new_fields, %{})
    %Searchex.Command.Build.Catalog.Scan.Doc{doc | fields: new_map}
  end

  def extract_doc_field(scan, doc, field) do
    if caps = Regex.named_captures(~r/#{scan.params.field_defs[field].regex}/, doc.body) do
      [head | _tail] = Map.values caps
      head
    else
      nil
    end
  end
end
