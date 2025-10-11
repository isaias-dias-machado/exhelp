# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: Isaías Dias Machado
defmodule Exhelp.LessHandler do
  def call(less_input) do
    tmp_filename = "~/.cache/exhelp/tmp"
    less_command = System.find_executable("less")

    if less_command == nil do
      IO.puts("less executable not found")
      System.stop(0)
    end

    # {:ok, logger} = File.open("log", [:write])
    File.write(tmp_filename, less_input)

    System.cmd(less_command, ["-R", tmp_filename], use_stdio: false)
  end
end
