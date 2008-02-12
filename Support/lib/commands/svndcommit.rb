require ENV['TM_SUPPORT_PATH'] + '/lib/ui.rb'

class SCM::Git::SVNDcommit < SCM::Git
  
  def initialize
    Dir.chdir(git_base)
  end
  
  def run
    puts "<h2>Committing to Subversion Repository</h2>"
    puts htmlize(svn_dcommit)
  end
  
  def svn_dcommit
    command("svn","dcommit")
  end
end