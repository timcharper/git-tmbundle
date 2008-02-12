require ENV['TM_SUPPORT_PATH'] + '/lib/ui.rb'

class SCM::Git::SVNRebase < SCM::Git
  
  def initialize
    Dir.chdir(git_base)
  end
  
  def run
    puts "<h2>Rebasing Subversion Repository</h2>"
    puts htmlize(svn_rebase)
  end
  
  def svn_rebase
    command("svn","rebase")
  end
end
