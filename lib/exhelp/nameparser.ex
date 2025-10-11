defmodule Exhelp.NameParser do
  @valid_introspection_funcs [?h, ?b]
  def parse_call(call) do
    <<help_fun, ?\s, name :: binary>> = call
    if is_valid_fun(help_fun) do
      help_fun_atom = <<help_fun>> |> String.to_atom()
      parsed_name = parse_name(name)
      {help_fun_atom, parsed_name}
    else
      :badfile
    end
  end

  defp is_valid_fun(help_fun) do
    if Enum.any?(@valid_introspection_funcs, fn el -> el == help_fun end) do
      true
    else
      false
    end
  end

  def parse_name(call) do
    parts = String.split(call, ".")

    if is_fun?(function = List.last(parts)) do
      module =
        Enum.take(parts, length(parts) - 1)
        |> Enum.join(".")

      case String.split(function, "/") do
        [fun, arity] ->
          {
            String.to_atom(module),
            String.to_atom(fun),
            String.to_integer(arity)
          }

        [fun] -> {String.to_atom(module), String.to_atom(fun)}
      end
    else
      String.to_atom(Enum.join(parts, "."))
    end
  end

  def is_fun?(str) do
    if hd(String.to_charlist(str)) in ?a..?z do
      true
    else
      false
    end
  end
end
