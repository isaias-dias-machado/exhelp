defmodule FzfHelper.Cli do
  @usage """
  usage: #{FzfHelper.Config.get_executable_name} [fetch]
  """
  def main(argv) do
    parsed =
      OptionParser.parse(argv, strict: [help: :boolean], aliases: [h: :help])

    # [help_fun, call] =
    case parsed do
      {[help: true], _, _} ->
        IO.puts(@usage)
        System.stop(0)

      {[], [], []} ->
        fuzzy_find()

      {_, ["fetch"], []} ->
        FzfHelper.Cache.Write.run()

      {_, ["clear"], []} ->
        File.rm_rf(FzfHelper.Config.get_dir_name)

      {_, _, invalid} ->
        IO.puts("Invalid argument: #{invalid}\n #{@usage}")
        System.stop(0)
    end

    # # FzfHelper.Cache.Read(help_fun, call)
  end

  def fuzzy_find() do
    fzf_input =
    case File.read(FzfHelper.Config.get_tags_file_name()) do
      {:ok, content} -> content
      {:error, _} -> 
    end

    call =
      FzfHelper.FzfHandler.call(fzf_input)
      |> String.slice(0..-2//1)

    less_input = FzfHelper.Cache.Read.run(call)

    less_executable = System.find_executable("less")

    less =
      Port.open(
        {:spawn_executable, less_executable},
        [:in, :out, :binary, args: ["-R"]]
      )

    Port.command(less, less_input)
    Port.close(less)
  end
end
