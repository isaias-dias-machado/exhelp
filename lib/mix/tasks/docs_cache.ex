# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: Isaías Dias Machado
defmodule Mix.Tasks.Docs.Cache do
  use Mix.Task

  @dir "~/.cache/exh" |> Path.expand()
  @tags "tags"

  @impl true
  def run(_args) do
    Mix.Task.run("compile")
    
    Mix.Task.run("loadpaths")
    
    Mix.Task.run("app.start")

    write_cache()
  end

  def write_cache() do
    IO.puts("INFO: Starting documentation caching...")
    start = System.monotonic_time(:millisecond)

    File.mkdir_p!(@dir)

    IO.puts("INFO: Caching into: #{@dir}")

    modules_files_list = :code.all_available()

    Enum.each(modules_files_list, fn {module, _file, _} ->
      module_string = to_string(module)
      <<first, _rest::binary>> = module_string
      atom = String.to_atom(if(first in ?A..?Z, do: "", else: ":")<>module_string)
      Code.ensure_loaded(atom)
    end)

    modules_set = get_set_from_existing_tags()

    :code.all_loaded()
    |> Enum.reduce(modules_set, &process/2)
    |> MapSet.to_list()
    |> Enum.join("\n")
    |> write_to_file()

    duration = System.monotonic_time(:millisecond) - start
    IO.puts("INFO: Documentation caching finished in: #{duration/1000} seconds")
  end

  def write_to_file(data) do
    File.write!("#{@dir}/#{@tags}", data)
  end

  def process({module, _path}, modules_set) do
    type = get_module_type(module)

    module_formatted_string =
      if(type == :elixir, do: "", else: ":") <> Atom.to_string(module)

    if MapSet.member?(modules_set, "h #{module_formatted_string}") do
      modules_set
    else
      docs = cache_module_docs(module, module_formatted_string)

      with :docs_v1 <- docs |> elem(0),
           true <- function_exported?(module, :module_info, 1) do
        funs = get_definitions(module, type, module_formatted_string)
        callbacks = get_callbacks(module, module_formatted_string)

        modules_set
        |> MapSet.put("h " <> module_formatted_string)
        |> MapSet.union(MapSet.new(funs))
        |> MapSet.union(MapSet.new(callbacks))
      else
        _ -> modules_set
      end
    end
  end

  def get_set_from_existing_tags() do
    filename = "#{@dir}/#{@tags}"
    case File.read(filename) do
      {:ok, content} -> 
        entries = String.split(content, "\n")
        MapSet.new(entries)

      _ -> MapSet.new()
    end
  end

  def cache_module_docs(module, module_formatted_string) do
    filepath =
      "#{@dir}/#{module_formatted_string}"

    docs = Code.fetch_docs(module)
    specs = Code.Typespec.fetch_specs(module)
    callbacks = Code.Typespec.fetch_callbacks(module)
    if !File.exists?(filepath) do
      File.write!(
        filepath,
        :erlang.term_to_binary({docs, specs, callbacks})
      )
    end

    docs
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
  
end
