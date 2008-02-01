require ENV['TM_SUPPORT_PATH'] + '/lib/ui.rb'

class SCM::Git::Pull
  include SCM::Git::CommonCommands
  
  def initialize
    Dir.chdir(git_base)
  end
  
  def run
    TextMate::UI.request_item(:title => "Pull", :prompt => "Select a remote source to pull from:", :items => sources) do |name|
      puts "<p>Pulling from remote source '#{name}'\n</p>"
      flush
      puts htmlize(pull(name))
    end
  end
  
  def pull(source)
    command("pull", source)
  end
end
