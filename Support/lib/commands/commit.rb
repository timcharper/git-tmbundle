class SCM::Git::Commit < SCM::Git
  
  def initialize
    @paths = paths
    @base  = git_base
    chdir_base
  end
end

