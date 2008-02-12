require ENV['TM_SUPPORT_PATH'] + '/lib/ui.rb'

class SCM::Git::Init < SCM::Git
  
  def initialize
    Dir.chdir(ENV['TM_PROJECT_DIRECTORY'])
  end
  
  def run
    puts "<h2>Initializing Git Repository in #{ENV['TM_PROJECT_DIRECTORY']}</h2>"
    puts htmlize(git_init)
  end
  
  def git_init
    command("init")
  end
end