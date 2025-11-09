# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: Isaías Dias Machado
defmodule Mix.Tasks.Docs.Cache do
  use Mix.Task

  @dir "~/.cache/exh" |> Path.expand()
  @tags Path.join(@dir, "tags")
  @checksums_dir Path.join(@dir, "checksums")
  @docs_dir Path.join(@dir, "docs")

  @impl true
  def run(args) do
    Mix.Task.run("compile")

    Mix.Task.run("loadpaths")

    Mix.Task.run("app.start")

    opts = [
      prune: List.first(args) == "prune"
    ]

    write_cache(opts)
  end

  def write_cache(opts) do
    start = System.monotonic_time(:millisecond)

    File.mkdir_p!(@checksums_dir)
    File.mkdir_p!(@docs_dir)

    IO.puts("INFO: Caching into: '#{@dir}'...")

    modules_files_list = :code.all_available()

    Enum.each(modules_files_list, fn {module, _file, _} ->
      module_string = to_string(module)
      <<first, _rest::binary>> = module_string
      atom = String.to_atom(if(first in ?A..?Z, do: "", else: ":") <> module_string)
      Code.ensure_loaded(atom)
    end)

    empty_set = MapSet.new()
    stats = %{keep: 0, create: 0, update: 0, delete: 0, no_docs: 0}

    acc = {empty_set, stats}

    {index_list, {found_modules, stats}} =
      :code.all_loaded()
      |> Enum.flat_map_reduce(acc, &process(&1, &2))

    index_list
    |> Enum.join("\n")
    |> write_to_file()

    stats =
      if opts[:prune],
        do: purge_not_found_modules(found_modules, stats),
        else: stats

    duration = System.monotonic_time(:millisecond) - start

    IO.puts("INFO: Caching stats:")
    total = stats[:keep] + stats[:create] + stats[:update]
    IO.puts("")
    IO.puts("Total:\t #{total}")
    IO.puts("Kept:\t #{stats[:keep]}")
    IO.puts("Created:\t #{stats[:create]}")
    IO.puts("Updated:\t #{stats[:update]}")
    IO.puts("Deleted:\t #{stats[:delete]}")
    IO.puts("Inspected:\t #{stats[:no_docs] + total}")
    IO.puts("")
    IO.puts("Duration:\t #{duration / 1000} seconds")
    IO.puts("")
  end

  def write_to_file(data) do
    File.write!(@tags, data)
  end

  def process({module, _path}, {modules_set, stats}) do
    type = get_module_type(module)

    module_formatted_string =
      if(type == :elixir, do: "", else: ":") <> Atom.to_string(module)

    filepath =
      "#{@docs_dir}/#{module_formatted_string}"

    docs = Code.fetch_docs(module)

    with :docs_v1 <- docs |> elem(0),
         true <- function_exported?(module, :module_info, 1) do
      op =
        cond do
          File.exists?(filepath) ->
            clear_stale_cache(module_formatted_string, docs)

          true ->
            :create
        end

      new_stats = Map.update(stats, op, 0, &(&1 + 1))

      new_modules_set =
        MapSet.put(modules_set, module_formatted_string)

      if op != :keep do
        cache_module_docs(module, docs, filepath)

        checksum_file =
          Path.join(@checksums_dir, module_formatted_string)

        File.write(checksum_file, "#{:erlang.phash2(docs)}")
      end

      funs = get_definitions(module, type, module_formatted_string)
      callbacks = get_callbacks(module, module_formatted_string)
      info = funs ++ callbacks
      index_list = ["h " <> module_formatted_string | info]

      {index_list, {new_modules_set, new_stats}}
    else
      _ ->
        new_stats = Map.update(stats, :no_docs, 0, &(&1+1))
        {[], {modules_set, new_stats}}
    end
  end

  def cache_module_docs(module, docs, filepath) do
    specs = Code.Typespec.fetch_specs(module)
    callbacks = Code.Typespec.fetch_callbacks(module)

    File.write!(
      filepath,
      :erlang.term_to_binary({docs, specs, callbacks})
    )
  end

  def format_module_name(module_string, :erlang) do
    if module_string in ?A..?Z, do: module_string, else: ":" <> module_string
  end

  def format_module_name(module_string, :elixir) do
    module_string
  end

  def get_module_type(module) do
    if function_exported?(module, :__info__, 1), do: :elixir, else: :erlang
  end

  def get_definitions(module, type, module_string) do
    case type do
      :erlang ->
        apply(module, :module_info, [:exports])
        |> definitions_to_string(module_string)

      :elixir ->
        (apply(module, :__info__, [:functions]) ++
           apply(module, :__info__, [:macros]))
        |> definitions_to_string(module_string)
    end
  end

  def get_callbacks(module, module_string) do
    state = {%{}, []}

    Code.Typespec.fetch_callbacks(module)
    |> elem(1)
    |> Enum.reduce(state, fn el, acc ->
      reduce_definitions(elem(el, 0), acc, module_string, "b")
    end)
    |> then(fn {_seen, list} -> list end)
  end

  def definitions_to_string(info, module_string) do
    acc = {%{}, []}

    info
    |> Enum.reduce(acc, &reduce_definitions(&1, &2, module_string, "h"))
    |> then(fn {_seen, list} -> list end)
  end

  def reduce_definitions({fun_atom, arity}, {seen, list}, module_string, help_fun) do
    new_seen = Map.update(seen, fun_atom, 0, &(&1 + 1))

    if Map.get(new_seen, fun_atom) == 1 do
      {
        new_seen,
        [
          "#{help_fun} #{module_string}.#{fun_atom}",
          format_entry(fun_atom, arity, module_string, help_fun) | list
        ]
      }
    else
      {
        new_seen,
        [format_entry(fun_atom, arity, module_string, help_fun) | list]
      }
    end
  end

  def format_entry(fun, arity, module_string, help_fun) do
    "#{help_fun} #{module_string}.#{fun}/#{arity}"
  end

  def clear_stale_cache(module_string, docs) do
    checksum_filepath = Path.join(@checksums_dir, module_string)

    this_checksum = :erlang.phash2(docs)

    case File.read(checksum_filepath) do
      {:ok, cached_checksum} ->
        if cached_checksum |> String.to_integer() != this_checksum do
          File.rm(checksum_filepath)
          module_filepath = Path.join(@docs_dir, module_string)
          File.rm(module_filepath)
          File.write(checksum_filepath, this_checksum)
          :update
        else
          :keep
        end

      {:error, _} ->
        raise "Docs module file has no corresponding checksum file"
    end
  end

  def purge_not_found_modules(found_modules, stats) do
    {:ok, existing_modules} = File.ls(@docs_dir)

    Enum.reduce(existing_modules, stats, fn module, stats ->
      if module not in found_modules do
        File.rm("#{@docs_dir}/#{module}")
        File.rm("#{@checksums_dir}/#{module}")
        Map.update(stats, :delete, 0, &(&1 + 1))
      else
        stats
      end
    end)
  end
end
