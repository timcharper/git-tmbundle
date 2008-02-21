require ENV['TM_SUPPORT_PATH'] + '/lib/ui.rb'

class SCM::Git::SVNFetch < SCM::Git
  
  def initialize
    Dir.chdir(git_base)
  end
  
  def run
    puts "<h2>Fetching Subversion Repository</h2>"
    puts htmlize(svn_fetch)
  end
  
  def svn_fetch
    command("svn","fetch")
  end
end
