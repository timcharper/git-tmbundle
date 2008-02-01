require ENV['TM_SUPPORT_PATH'] + '/lib/ui.rb'

class SCM::Git::Push
  include SCM::Git::CommonCommands
  
  def initialize
    Dir.chdir(git_base)
  end
  
  def run
    TextMate::UI.request_item(:title => "Push", :prompt => "Select a remote source to push to:", :items => sources) do |name|
      puts "<p>Pushing to remote source '#{name}'\n</p>"
      flush
      puts htmlize(push(name))
    end
  end
  
  def push(source)
    command("push", source)
  end
end