defmodule FzfHelper.LessHandler do
  def call(less_input) do
    less_command = System.find_executable("less")

    if less_command == nil do
      IO.puts("less executable not found")
      System.stop(0)
    end

    Process.flag(:trap_exit, true)
    pid = spawn_link(fn -> open_less(less_command, less_input) end)

    gl = :erlang.group_leader()
    {:ok, void} = File.open("/dev/null")
    shell = IEx.Broker.shell()
    :erlang.group_leader(void, shell)
    receive do
      _ -> :ok
    end
    :erlang.group_leader(gl, shell)
  end

  def open_less(executable, input) do
    less = Port.open(
      {:spawn_executable, executable},
      [:out, :binary, :stream, :exit_status, args: ["-R"]]
    )
    Port.command(less, input)
  end
end
