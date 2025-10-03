defmodule FzfHelper.FzfHandler do
  def call(fzf_input) do
    fzf_command = System.find_executable("fzf")

    if fzf_command == nil do
      IO.puts("fzf executable not found")
      System.stop(0)
    end

    fzf = Port.open({:spawn_executable, fzf_command}, [:in, :out, :binary, :exit_status])
    Port.command(fzf, fzf_input)

    handle_msgs(fzf)
  end

  def handle_msgs(port) do
    receive do
      {^port, {:exit_status, _}} ->
        receive do
          {^port, {:data, data}} ->
            data
        after
          0 -> nil
        end

      {^port, {:data, data}} ->
        receive do
          _ -> nil
        after
          0 -> nil
        end
        data
    end
  end
end
