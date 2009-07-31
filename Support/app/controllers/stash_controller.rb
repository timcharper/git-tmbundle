# encoding: utf-8
require ENV['TM_SUPPORT_PATH'] + '/lib/ui.rb'

class StashController < ApplicationController
  layout "application", :except => ["clear"]
  def show
    if git.stash.list.empty?
      puts "Stash list is empty"
    end

    stash_item = select_stash

    if stash_item.nil?
      puts "Aborted"
      return
    end
    
    puts "<h2>Diff for stash ‘#{stash_item[:description]}’</h2>"
    render("diff/_diff_results", :locals => {:diff_results => (git.stash.diff(stash_item[:name]))})
  end
  
  def pop
    stash_item = select_stash(:prompt => "Select a stash to pop")
    if stash_item.nil?
      puts "Cancelled"
      return
    end
    puts "<h2>Popping stash '#{stash_item[:description]}'</h2>"
    flush
    
    stash_diff = git.stash.diff(stash_item[:name])
    
    stash_it = lambda {
      git.stash.pop(stash_item[:name])
    }

    result = stash_it.call

    if result.match(/Cannot restore on top of a dirty state/)
      response = TextMate::UI.alert(:warning, "You're not on a clean working copy", "You may want to commit your outstanding changes before stashing.\nWould you like to apply your stash anyways? (could cause conflicts)", "No", "Yes")
      if response == "Yes"
        git.command("add", ".")
        result = stash_it.call
        git.command("reset")
      else
        return
      end
    end
    
    status_data = git.parse_status(result)
    if status_data.empty?
      puts "I didn't understand git's response.  Perhaps you can?"
      puts "<pre>#{result}</pre>"
      return
    end
    
    puts "<h2>Successfully applied</h2>"
    puts "<h2>Project Status:</h2>"
    render "status/_status", :locals => {:status_data => status_data}
    
    puts "<h2>Diff of stash applied:</h2>"
    render("/diff/_diff_results", :locals => {:diff_results => stash_diff})
    
    rescan_project
  end
  
  def save
    untracked_files = git.list_files(git.path, :type => "o")
    if untracked_files.length >= 1
      response = TextMate::UI.alert(:warning, "Untracked files in working copy", "Would you like to include the following untracked files in your stash?:\n#{untracked_files * "\n"}\n", "Add them", "Leave them out", "Cancel")
      case response
      when "Add them"
        git.command("add", ".")
      when "Cancel", nil
        return exit_discard
      end
    end
    
    stash_description = TextMate::UI.request_string(:title => "Stash", :prompt => "Describe stash:", :default => "WIP: ")
    if stash_description.nil?
      return exit_discard
    end
    stash_description = "WIP" if stash_description.empty?
    
    result = git.stash.save(stash_description)
    if result.match(/Saved working directory and index state/)
      
    end
    puts result
    rescan_project
  end
  
  def clear
    if git.stash.list.empty?
      puts "No stashes for current branch (#{git.branch.current_name})"
      return
    end

    stash_text_list = git.stash.list.map{|s| "#{s[:id]} - #{s[:description]}"} * "\n"
    response = TextMate::UI.alert(:warning, "Clear all stashes?", "Do you really want to clear the following stashes? \n#{stash_text_list}", 'Yes', 'Cancel') 
    if response == 'Yes'
      git.stash.clear
      puts "Stash cleared"
    else
      puts "Cancelled"
    end
  end
  
  protected
    def select_stash(options={})
      options = {:title => "Select stash", :prompt => "Select a stash", :items => git.stash.list.map{|s| "#{s[:id]} - #{s[:description]}"}}.merge(options)
      TextMate::UI.request_item(options) do |stash_id|
        selected_stash_entry = git.stash.list.find { |s| s[:id].to_i == stash_id.to_i }
        return selected_stash_entry
      end
      nil
    end
end