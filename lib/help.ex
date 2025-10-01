# TODO: macros, callbacks
defmodule Help do
  def run() do
    modules = get_modules()
    functions = get_functions(modules)
    string =
      modules
      |> Enum.zip(functions)
      |> Enum.filter(fn el -> elem(el, 1) != false end)
      |> Enum.map(&transform_data/1)
      |> List.flatten()
      |> Enum.join("\n")
    
    File.write("elixir_resources", string)
  end

  def transform_data({module_atom, fun_list}) do
    module_string = Atom.to_string(module_atom)
    fun_path_list =
      fun_list
      |> Enum.map(fn fun -> [module_string, fun] |> Enum.join(".") end)
    [module_string | fun_path_list]
  end

  defp get_functions(modules) do
    modules
    |> Enum.map(&get_info/1)
  end

  defp get_info(module) do
    case function_exported?(module, :__info__, 1) do
      true -> module.__info__(:functions) |> functions_to_string()
      _ -> false
    end
  end

  defp functions_to_string(info) do
    info
    |> Enum.map(&add_airity/1)
  end

  defp add_airity({function, airity}) do
    [Atom.to_string(function), Integer.to_string(airity)] |> Enum.join("/")
  end

  defp get_modules() do
    :code.all_loaded()
    |> Enum.map(fn el -> elem(el, 0) end)
  end
end
