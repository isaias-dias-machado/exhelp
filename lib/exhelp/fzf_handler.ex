# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: Isaías Dias Machado
defmodule Exhelp.FzfHandler do
  def call(fzf_input) do
    fzf_command = System.find_executable("fzf")

    if fzf_command == nil do
      IO.puts("fzf executable not found")
      System.stop(0)
    end

    old_gl = Exhelp.GL.capture()
    port = Port.open({:spawn_executable, fzf_command}, [:binary, :exit_status])
    Port.command(port, fzf_input)

    receive do
      {^port, {:exit_status, _}} ->
        receive do
          {^port, {:data, data}} ->
            data
        after
          0 ->
            Exhelp.GL.restore(old_gl)
            nil
        end

      {^port, {:data, data}} ->
        receive do
          _ -> nil
        after
          0 -> nil
        end
        Exhelp.GL.restore(old_gl)
        data
    end
  end
end
