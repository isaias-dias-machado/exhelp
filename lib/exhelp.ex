# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: Isaías Dias Machado
defmodule Exhelp do
  @help """
  usage:
    exh [fetch]

  No arguments invocation calls fzf to browse cached documents.

  Run with the 'fetch' argument to cache you loaded modules first.
  """

  def exh, do: process_fzf()
  def exh("fetch"), do: Exhelp.Cache.Write.run()
  def exh("clean"), do: File.rm_rf(Exhelp.Config.get_dir_name()) |> elem(0)
  # def exh("ctags"), do: File.rm_rf(Exhelp.Config.get_dir_name()) |> elem(0)
  def exh(_), do: IO.puts(@help)

  defp process_fzf() do
    case File.read(Exhelp.Config.get_tags_file_name()) do
      {:ok, content} ->
        Exhelp.FzfHandler.call(content)
        |> handle_fzf()

      {:error, _} ->
        IO.puts("Run 'exh fetch' first")
    end
  end

  defp handle_fzf(nil), do: :exit
  defp handle_fzf(data) do
    {help_fun, call} =
      data
      |> String.slice(0..-2//1)
      |> Exhelp.NameParser.parse_call()

    ExUnit.CaptureIO.capture_io(fn ->
      apply(IEx.Introspection, help_fun, [call])
    end)
    |> Exhelp.LessHandler.call()
  end
end
