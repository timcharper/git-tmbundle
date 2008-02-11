class SCM::Git::Gitk
  include SCM::Git::CommonCommands
  def initialize
    @base = git_base
    Dir.chdir(@base)
  end
  
end