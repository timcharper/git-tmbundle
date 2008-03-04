require ENV['TM_SUPPORT_PATH'] + '/lib/ui.rb'

class SCM::Git::Merge < SCM::Git
  def initialize
    @base = git_base
    chdir_base
  end
end
