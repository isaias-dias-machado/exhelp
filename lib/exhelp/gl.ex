defmodule Exhelp.GL do
  def capture do
    iex_pid = IEx.Broker.shell
    gl = Process.group_leader()
    # {:ok, new_gl} = StringIO.open("")
    new_gl =
      case start_link(nil) do
        {:ok, pid} -> pid
        {:error, {:already_started, pid}} -> pid
      end
    Process.group_leader(iex_pid, new_gl)
    gl
  end

  def restore(old_gl) do
    iex_pid = IEx.Broker.shell()
    Process.group_leader(iex_pid, old_gl)
    GenServer.stop(__MODULE__)
  end

  use GenServer
  
  @doc false
  def start_link(init_args) do
    GenServer.start_link(__MODULE__, init_args, name: __MODULE__)
  end
  
  @impl true
  def init(_state) do
    {:ok, pid} = StringIO.open("")
    {:ok, pid}
  end

  @impl true

  def handle_info(io_request, io_device) do
    send(io_device, io_request)
    {:noreply, io_device}
  end
end
