# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: Isaías Dias Machado
defmodule Exhelp.Cache.Read do
  def run(call) do
    <<help_fun, ?\s, mod_fun::binary>> = call
    parsed_call = parse_call(mod_fun)
    module_string = parsed_call |> elem(0)
    
    case read_docs(module_string) do
      {:ok, docs} -> process(docs, parsed_call)
      :enoent -> :enoent
    end
  end

  defp process(
    {
      {
        :docs_v1,
        _annotation,
        beam_language,
        format,
        module_doc,
        metadata,
        docs
      },
      {:ok, specs},
      {:ok, _callbacks}
    },
    parsed_call
    ) do
      case parsed_call do
        {module} ->
          print_doc([module], [], format, module_doc, metadata)

        {_module, function} ->
          docs
          |> Enum.filter(&filter_by_function(String.to_atom(function), &1))
          |> Enum.map(&mod_fun_arity(&1, beam_language, format, specs))

        {_module, function, arity} ->
          docs
          |> Enum.filter(
            &filter_by_function_arity(
              String.to_atom(function),
              String.to_integer(arity),
              &1
            )
          )
          |> Enum.map(
            &mod_fun_arity(
              &1,
              beam_language,
              format,
              specs
            )
          )
      end
      |> IO.iodata_to_binary()
  end

  def mod_fun_arity(
        {{kind, fun, arity}, _line, headings, body, metadata},
        language,
        format,
        specs
      ) do
    spec = get_spec(specs, fun, arity)

    print_doc(
      format_headings(language, kind, headings),
      spec,
      format,
      body,
      metadata
    )
  end

  def filter_by_function(function, entry) do
    case entry do
      {{_, ^function, _}, _, _, _, _} -> true
      _ -> false
    end
  end

  def filter_by_function_arity(function, arity, entry) do
    case entry do
      {{_, ^function, ^arity}, _, _, _, _} -> true
      _ -> false
    end
  end

  defp print_doc(headings, types, format, doc, metadata) do
    doc = translate_doc(doc) || ""
    opts = IEx.Config.ansi_docs()
    IO.ANSI.Docs.print_headings(headings, opts)
    IO.write(types)
    IO.ANSI.Docs.print_metadata(metadata, opts)
    IO.ANSI.Docs.print(doc, format, opts)
  end

  defp translate_doc(%{"en" => doc}), do: doc
  defp translate_doc(_), do: nil

  defp format_headings(:elixir, :function, heading),
    do: Enum.map(heading, &("def " <> &1))

  defp format_headings(:elixir, :macro, heading),
    do: Enum.map(heading, &("defmacro " <> &1))

  defp format_headings(_, _, heading), do: heading

  defp get_spec(all_specs, fun_name, arity) do
    {_, specs} = List.keyfind(all_specs, {fun_name, arity}, 0)

    formatted =
      Enum.map(specs, fn spec ->
        Code.Typespec.spec_to_quoted(fun_name, spec)
        |> format_typespec(:spec, 2)
      end)

    [formatted, ?\n]
  end

  def format_typespec(definition, kind, nesting) do
    {:@, [], [{kind, [], [definition]}]}
    |> Code.quoted_to_algebra()
    |> Inspect.Algebra.format(IEx.Config.width())
    |> IO.iodata_to_binary()
    |> color_prefix_with_line()
    |> indent(nesting)
  end

  defp indent(content, 0) do
    [content, ?\n]
  end

  defp indent(content, nesting) do
    whitespace = String.duplicate(" ", nesting)
    [whitespace, String.replace(content, "\n", "\n#{whitespace}"), ?\n]
  end

  defp color_prefix_with_line(string) do
    [left, right] = :binary.split(string, " ")
    IEx.color(:doc_inline_code, left) <> " " <> right
  end

  def parse_call(call) do
    parts = String.split(call, ".")

    if is_fun?(function = List.last(parts)) do
      module =
        Enum.take(parts, length(parts) - 1)
        |> Enum.join(".")

      case String.split(function, "/") do
        [fun, arity] -> {module, fun, arity}
        [fun] -> {module, fun}
      end
    else
      {Enum.join(parts, ".")}
    end
  end

  def is_fun?(str) do
    if hd(String.to_charlist(str)) in ?a..?z do
      true
    else
      false
    end
  end

  def read_docs(module) when is_binary(module) do
    file_path = Exhelp.Config.get_dir_name() <> "/" <> module

    case File.read(file_path) do
      {:ok, doc} -> {:ok, :erlang.binary_to_term(doc)}
      _ -> :enoent
    end
  end
end
