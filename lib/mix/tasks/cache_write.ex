# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: Isaías Dias Machado
defmodule Mix.Tasks.Cache.Write do
  require Logger

  def run() do
    Logger.info("Starting documentation caching...")

    target_dir = ExHelp.Config.get_dir_name()

    File.mkdir_p(target_dir)

    Logger.info("Caching into: #{target_dir}")

    modules_files_list = :code.all_available()

    Enum.each(modules_files_list, fn {module, _file, _} ->
      module_string = to_string(module)
      <<first, _rest::binary>> = module_string
      atom = String.to_atom(if(first in ?A..?Z, do: "", else: ":")<>module_string)
      Code.ensure_loaded(atom)
    end)

    :code.all_loaded()
    |> Enum.flat_map(&process/1)
    |> Enum.join("\n")
    |> write_to_file()

    Logger.info(" documentation caching finished.")
  end

  def write_to_file(data) do
    File.write!(ExHelp.Config.get_tags_file_name(), data)
  end

  # TODO: Can be optimized -> load tags to a map and skip the process step if
  # module is already registered -> add new tags to the map -> replace the
  # contents of the tags file with the map.
  def process({module, _path}) do
    type = get_module_type(module)

    module_formatted_string =
      if(type == :elixir, do: "", else: ":") <> Atom.to_string(module)

    docs = cache_module_docs(module, module_formatted_string)

    with :docs_v1 <- docs |> elem(0),
         true <- function_exported?(module, :module_info, 1) do
      funs = get_definitions(module, type, module_formatted_string)
      callbacks = get_callbacks(module, module_formatted_string)
      info = funs ++ callbacks

      ["h " <> module_formatted_string | info]
    else
      _ -> []
    end
  end

  def cache_module_docs(module, module_formatted_string) do
    filepath =
      "#{ExHelp.Config.get_dir_name()}/#{module_formatted_string}"

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
