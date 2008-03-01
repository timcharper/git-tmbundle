require ENV['TM_SUPPORT_PATH'] + '/lib/ui.rb'

class BranchController < ApplicationController
  def switch
    locals = git.branch_names(:local)
    remotes = git.branch_names(:remote)
    current = git.current_branch
    
    items = ([current] + locals + remotes).uniq
    
    if items.length == 0
      puts "Current branch is '#{current}'. There are no other branches."
    else
      target_branch = TextMate::UI.request_item(:title => "Switch to Branch", :prompt => "Current branch is '#{current}'.\nSelect a new branch to switch to:", :items => items) 
      if target_branch.blank?
        exit_discard
      end
      
      if locals.include?(target_branch)
        switch_local(target_branch)
      else
        switch_remote(target_branch)
      end
    end
  end
  
  def create
    if name = TextMate::UI.request_string(:title => "Create Branch", :prompt => "Enter the name of the new branch:")
      puts git.create_branch(name)
    end
  end
  
  def delete
    locals = git.branch_names(:local)
    remotes = git.branch_names(:remote)
    current = git.current_branch
    
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
      
        if git.branch_names(:local).include?(new_branch_name)
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
      output = git.command("branch", "-d", target).strip
      if output == "Deleted branch #{target}."
        TextMate::UI.alert(:informational, "Success", output, 'OK') 
      elsif output.match(/error.+(not a strict subset|not an ancestor of your current HEAD)/)
        response = TextMate::UI.alert(:warning, "Warning", "Branch '#{target}' is not a strict subset of your current HEAD (it has unmerged changes)\nReally delete it?", 'Yes', 'No') 
        return false if response != 'Yes'
      
        output = git.command("branch", "-D", target).strip
        TextMate::UI.alert(:informational, "Delete branch", output, 'OK')
      else
        response = TextMate::UI.alert(:warning, "Hmmm", "I didn't understand's git's response, perhaps you can make sense of it?\n#{output}", 'Ok') 
      end
    
      true
    end
  
    def delete_remote(target)
      # detect remote
      remote_alias, branch = target.split("/")
      output = git.command("push", remote_alias, ":#{branch}")
      case output
      when /refs\/heads\/#{branch}: .+\-\> deleted/, /\[deleted\]/
        TextMate::UI.alert(:informational, "Success", "Deleted remote branch #{target}.", "OK")
        return true
      when /error: dst refspec .+ does not match any existing ref on the remote and does not start with refs\/./
        TextMate::UI.alert(:warning, "Delete branch failed!", "The source '#{remote_alias}' reported that the branch '#{branch}' does not exist.\nTry running the prune remote stale branches command?", "OK")
      else
        TextMate::UI.alert(:informational, "Deleted remote branch", "I couldn't make sense of this.  Perhaps you can?\n#{output}", 'OK')
      end
    end
    
    def switch_local(target_branch)
      output = git.switch_to_branch(target_branch)
      case output
      when /fatal: you need to resolve your current index first/
        TextMate::UI.alert(:warning, "Error - couldn't switch", "Git said:\n#{output}\nYou're probably in the middle of a conflicted merge, and need to commit", "OK")
        exit_discard
      when /fatal: Entry '(.+)' not uptodate\. Cannot merge\./
        response = TextMate::UI.alert(:informational, "Conflict detected if you switch", "There are uncommitted changes that will cause conflicts by this switch (#{$1}).\nSwitch anyways?", "No", "Yes")
        if response=="Yes"
          output = git.command("checkout", "-m", target_branch)
          puts htmlize(output)
          exit_show_html
        else
          exit_discard
        end
      else
        puts htmlize(output)
        exit_show_html
      end
    end
  
end