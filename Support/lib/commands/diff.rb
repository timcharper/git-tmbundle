class SCM::Git::Diff
  include SCM::Git::CommonCommands
    
  def diff(file, base = nil)
    base = File.expand_path("..", git_dir(file)) if base.nil?
    Dir.chdir(base)
    file = '.' if file == base
    command("diff", file.sub(/^#{Regexp.escape base}\//, ''))
  end
end