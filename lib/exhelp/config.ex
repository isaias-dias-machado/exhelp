# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: Isaías Dias Machado
defmodule Exhelp.Config do
  @dir "~/.cache/exhelp"
  @tags_file "tags"

  def get_dir_name, do: Path.expand(@dir)
  def get_tags_file_name, do: Path.join(get_dir_name(), @tags_file)
end
