# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: Isaías Dias Machado
defmodule Exhelp.Macros do
  defmacro exh(), do: Exhelp.exh()
  defmacro exh(args) do
    {atom, _, _} = args
    arg_str = Atom.to_string(atom)
    Exhelp.exh(arg_str)
  end
end
