# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: Isaías Dias Machado
defmodule ExHelp.Cli do
  def get_cli_help() do
    """
      usage:
        exh [fetch | clear]

      No arguments invocation calls fzf to browse cached documents.

      Run with 'fetch' to cache you loaded modules first.

      Run with 'clear' to clear the cache files.
    """
  end

  def main(argv) do
    parsed =
      OptionParser.parse(argv,
        strict: [help: :boolean, clear: :boolean, fetch: :boolean],
        aliases: [h: :help])

    case parsed do
      {[help: true], _, _} ->
        IO.puts(get_cli_help())
        System.halt()

      {[clear: true], _, []} ->
        dir = ExHelp.Config.get_dir_name()
        IO.puts("Clearing cache from #{dir}")
        File.rm_rf(dir)

      {_, [_help_fun, call], []} ->
        ExHelp.Cache.Read.run(call)

      {_, _, _} ->
        IO.puts(get_cli_help())
        System.halt(1)
    end
  end
end
