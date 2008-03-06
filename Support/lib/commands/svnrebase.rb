require ENV['TM_SUPPORT_PATH'] + '/lib/ui.rb'

class SCM::Git::SVNRebase < SCM::Git
  
  def initialize
    Dir.chdir(git_base)
  end
  
end
