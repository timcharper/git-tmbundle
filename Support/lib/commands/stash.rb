require ENV['TM_SUPPORT_PATH'] + '/lib/ui.rb'

class SCM::Git::Stash < SCM::Git
  def initialize()
    chdir_base
  end
  
  def stash_list(reload = false)
    @stash_list = nil if reload
    
    @stash_list ||= command("stash", "list").split("\n").map do |line|
      /^(.+?):(.+)$/.match(line)
      name = $1
      description = $2
      /([0-9]+)/.match(name)
      {:id => $1.to_i, :name => name, :description => description}
    end
  end
  
  def run_stash_save
    untracked_files = list_files(git_base, :type => "o")
    if untracked_files.length >= 1
      response = TextMate::UI.alert(:warning, "Untracked files in working copy", "Would you like to include the following untracked files in your stash?:\n#{untracked_files * "\n"}\n", "Add them", "Leave them out", "Cancel")
      case response
      when "Add them"
        command("add", ".")
      when "Cancel", nil
        return exit_discard
      end
    end
    
    stash_description = TextMate::UI.request_string(:title => "Stash", :prompt => "Describe stash:", :default => "WIP: ")
    if stash_description.nil?
      return exit_discard
    end
    stash_description = "WIP" if stash_description.empty?
    
    puts stash_save(stash_description)

    rescan_project
    return exit_show_html
  end
  
  def stash_save(desciption = "")
    params = []
    params << desciption unless desciption.nil? || desciption.empty?
    command("stash", "save", *params)
  end
  
  def stash_diff(name)
    SCM::Git::Diff.parse_diff(command("stash", "show", "-p", name))
  end
  
  def apply_stash(name)
    command("stash", "apply", "--index", name)
  end
  
  def clear_with_confirmation
    stash_text_list = stash_list.map{|s| "#{s[:id]} - #{s[:description]}"} * "\n"
    response = TextMate::UI.alert(:warning, "Clear all stashes?", "Do you really want to clear the following stashes? \n#{stash_text_list}", 'Yes', 'Cancel') 
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
    options = {:title => "Select stash", :prompt => "Select a stash", :items => stash_list.map{|s| "#{s[:id]} - #{s[:description]}"}}.merge(options)
    TextMate::UI.request_item(options) do |stash_id|
      selected_stash_entry = stash_list.find { |s| s[:id].to_i == stash_id.to_i}
      return selected_stash_entry
    end
    
    nil
  end
end