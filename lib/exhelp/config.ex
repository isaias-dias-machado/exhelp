# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: Isaías Dias Machado
defmodule ExHelp.Config do
  @dir_name (
    System.get_env("EXH_CACHE_DIR") || "~/.cache/exh"
    |> Path.expand()
  )

  @tags_file (
    tags_file = System.get_env("EXH_TAGS_FILE") || "tags"
    Path.join(@dir_name, tags_file)
  )

  def get_dir_name, do: @dir_name

  def get_tags_file_name, do: @tags_file

  def get_executable_name, do: Application.get_env(:fzf_help, :script_name)
end
