require ENV['TM_SUPPORT_PATH'] + '/lib/ui.rb'

class SCM::Git::Stash
  include SCM::Git::CommonCommands
  def initialize()
    Dir.chdir(git_base)
  end
  
  def stashes
    @stashes = command("stash", "list").split("\n").map do |line|
      /^(.+?):(.+)$/.match(line)
      name = $1
      description = $2
      /([0-9]+)/.match(name)
      {:id => $1.to_i, :name => name, :description => description}
    end
  end
  
  def stash
    command("stash")
  end
  
  def stash_diff(name)
    SCM::Git::Diff.parse_diff(command("stash", "show", "-p", name))
  end
  
  def apply_stash(name)
    command("stash", "apply", name)
  end
  
  def clear_with_confirmation
    response = TextMate::UI.alert(:warning, "Clear all stashes?", "Do you really want to clear the following stashes? \n#{stashes.map{|s| s[:id] + ' - ' + s[:description]} * "\n"}", 'Yes', 'Cancel') 
    if response == 'Yes'
      clear
      true
    else
      false
    end
  end
  
  def clear
    command("stash", "clear")
  end
  
  def select_stash(options={})
    @stashes = stashes
    options = {:title => "Select stash", :prompt => "Select a stash", :items => stashes.map{|s| "#{s[:id]} - #{s[:description]}"}}.merge(options)
    TextMate::UI.request_item(options) do |stash_id|
      return @stashes.find { |s| s[:id].to_i == stash_id.to_i}[:name]
    end
    
    nil
  end
end