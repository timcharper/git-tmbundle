require LIB_ROOT + '/ui.rb'

class BranchController < ApplicationController
  layout "application", :except => [:create, :delete]
  
  include SubmoduleHelper::Update
  
  def switch
    current_name = git.branch.current_name
    items = (git.branch.names(:local) + git.branch.names(:remote)).compact.with_this_at_front(current_name)
    if items.length == 0
      puts "Current branch is '#{current_name || '(no branch)'}'. There are no other branches."
    else
      target_branch = TextMate::UI.request_item(:title => "Switch to Branch", :prompt => "Current branch is '#{current_name || '(no branch)'}'.\nSelect a new branch to switch to:", :items => items, :force_pick => true) 
      if target_branch.blank?
        exit_discard
      end
      
      if git.branch.names(:local).include?(target_branch)
        switch_local(target_branch)
      else
        switch_remote(target_branch)
      end
    end
  end
  
  def create
    if name = TextMate::UI.request_string(:title => "Create Branch", :prompt => "Enter the name of the new branch:")
      puts git.branch.create_and_switch(name)
    end
  end
  
  def delete
    locals = git.branch.list_names(:local)
    remotes = git.branch.list_names(:remote)
    current = git.branch.current_name
    
    all = locals + remotes
    
    if all.length == 1
      TextMate::UI.alert(:warning, "Error!", "There's only one branch, and you can't delete all of the branches", 'OK') 
      return false
    end

    if all.length == 0
      puts "Current branch is '#{current}'. There are no other branches."
    else
      target = TextMate::UI.request_item(:title => "Delete Branch", :prompt => "Select the branch to delete:", :items => locals + remotes)
      if target.blank?
        return exit_discard
      end
      
      if target == current
        TextMate::UI.alert(:warning, "Error!", "You cannot delete the branch you are currently on (switch first)", 'OK') 
        return false
      end
      
      if remotes.include?(target)
        delete_remote(target)
      elsif 
        delete_local(target)
      end
    end
  end
  
  def merge
    # prompt for which branch to merge from
    @c_branch = git.branch.current_name
    all_branches = git.branch.list_names(:all) - [@c_branch]
    
    @merge_from_branch = TextMate::UI.request_item(:title => "Merge", :prompt => "Merge which branch into '#{@c_branch}':", :items => all_branches, :force_pick => true)
    if @merge_from_branch.blank?
      puts "Aborted"
      return
    end
    
    puts "<h2>Merging #{@merge_from_branch} into #{@c_branch}</h2>"
    
    with_submodule_updating do
      @result = git.merge(@merge_from_branch)
      render "merge"
    end
    rescan_project
    true
  end
    
  protected
    def switch_remote(target)
      remote_alias, remote_branch_name = target.split("/")
    
      repeat = false
      begin
        new_branch_name = TextMate::UI.request_string(:title => "Switch to remote branch", :prompt => "You must set up a local tracking branch to work on '#{target}'.\nWhat would you like to name the local tracking branch?", :default => remote_branch_name)
        new_branch_name = new_branch_name.to_s.strip
        if new_branch_name.blank?
          return exit_discard
        end
      
        if git.branch.list_names(:local).include?(new_branch_name)
          response = TextMate::UI.alert(:warning, "Branch name already taken!", "The branch name '#{new_branch_name}' is already in use.\nVery likely this is the branch you want to work on.\nIf not, pick another name.", "Pick another name", "Switch to it", "Cancel")
          return exit_discard if response == "Cancel"
          return switch_local(new_branch_name) if response == "Switch to it"
          repeat = true
        end
      end while repeat
    
      output = git.command("branch", "--track", new_branch_name, target)
      puts htmlize(output)
      switch_local(new_branch_name)
    end
  
    def delete_local(target)
      result = git.branch.delete(target)
      case result[:outcome]
      when :success
        TextMate::UI.alert(:informational, "Success", result[:output], 'OK') 
      when :unmerged
        return false if TextMate::UI.alert(:warning, "Warning", "Branch '#{target}' is not an ancestor of your current HEAD (it has unmerged changes)\nReally delete it?", 'Yes', 'No') != 'Yes'
        result = git.branch.delete(target, :force => true)
        if result[:outcome] == :success
          TextMate::UI.alert(:informational, "Deleted branch", result[:output], 'OK')
        else
          TextMate::UI.alert(:informational, "Still couldn't delete branch", "Git said:\n#{result[:output]}", 'OK')
          return false
        end
      else
        TextMate::UI.alert(:warning, "Hmmm", "I didn't understand's git's response, perhaps you can make sense of it?\n#{result[:output].to_s}", 'Ok') 
        return false
      end
      true
    end
  
    def delete_remote(target)
      # detect remote
      result = git.branch.delete(target)
      case result[:outcome]
      when :success
        TextMate::UI.alert(:informational, "Success", "Deleted remote branch #{target}.", "OK")
        return true
      when :branch_not_found
        TextMate::UI.alert(:warning, "Delete branch failed!", "The source '#{result[:remote]}' reported that the branch '#{result[:branch]}' does not exist.\nTry running the prune remote stale branches command?", "OK")
        return false
      else
        TextMate::UI.alert(:informational, "Delete remote branch", "I couldn't make sense of this.  Perhaps you can?\n#{result[:output]}", 'OK')
      end
    end
    
    def switch_local(target_branch)
      with_submodule_updating do
        output = git.branch.switch(target_branch)
        case output
        when /fatal: you need to resolve your current index first/
          TextMate::UI.alert(:warning, "Error - couldn't switch", "Git said:\n#{output}\nYou're probably in the middle of a conflicted merge, and need to commit", "OK")
          output_discard
        when /(fatal|error): Entry '(.+)' not uptodate\. Cannot merge\./
          response = TextMate::UI.alert(:informational, "Conflicts may happen if you switch", "There are uncommitted changes that might cause conflicts by this switch (#{$2}).\nSwitch anyways?", "No", "Yes")
          if response=="Yes"
            output = git.command("checkout", "-m", target_branch)
            puts htmlize(output)
            output_show_html and return
          else
            output_discard and return
          end
        else
          puts htmlize(output)
          output_show_html
          rescan_project
        end
      end
    end
end