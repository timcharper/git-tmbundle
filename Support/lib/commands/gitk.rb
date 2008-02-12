class SCM::Git::Gitk
  include SCM::Git::CommonCommands
  def initialize
    Dir.chdir(ENV['TM_PROJECT_DIRECTORY'])
  end
  
  def run
    %x{gitk --all > /dev/null 2>&1 &}
  end
end