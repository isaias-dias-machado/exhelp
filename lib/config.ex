defmodule FzfHelper.Config do
  @dir "~/.cache/fzfhelper"
  @tags_file "tags"

  def get_dir_name, do: Path.expand(@dir)
  def get_tags_file_name, do: Path.join(get_dir_name(), @tags_file)
  def get_executable_name, do: Application.get_env(:fzf_helper, :script_name)
end
