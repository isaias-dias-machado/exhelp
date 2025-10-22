# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: Isaías Dias Machado
defmodule Exhelp.LessHandler do
  def call(less_input) do
    tmp_filename = "~/.cache/exhelp/tmp" |> Path.expand()
    less_command = System.find_executable("less")

    if less_command == nil do
      IO.puts("less executable not found")
      System.stop(0)
    end

    File.write(tmp_filename, less_input)

    old_gl = Exhelp.GL.capture
    System.cmd("less", ["-R", tmp_filename], use_stdio: false)
    receive do
      _exit_status ->
        :ok
    end
    Exhelp.GL.restore(old_gl)
  end
end
