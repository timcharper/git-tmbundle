require ENV['TM_SUPPORT_PATH'] + '/lib/ui.rb'

class SCM::Git::Branch < SCM::Git
  def initialize
    # git_base = File.expand_path('..', git_dir(paths.first))
    chdir_base
  end
  
  def run_switch
    locals = branch_names(:local)
    remotes = branch_names(:remote)
    current = current_branch
    
    items = ([current] + locals + remotes).uniq
    
    if items.length == 0
      puts "Current branch is '#{current}'. There are no other branches."
    else
      target_branch = TextMate::UI.request_item(:title => "Switch to Branch", :prompt => "Current branch is '#{current}'.\nSelect a new branch to switch to:", :items => items) 
      if target_branch.blank?
        exit_discard
      end
      
      if locals.include?(target_branch)
        run_switch_local(target_branch)
      else
        run_switch_remote(target_branch)
      end
    end
  end
  
  def run_switch_local(target_branch)
    output = switch_to_branch(target_branch)
    case output
    when /fatal: you need to resolve your current index first/
      TextMate::UI.alert(:warning, "Error - couldn't switch", "Git said:\n#{output}\nYou're probably in the middle of a conflicted merge, and need to commit", "OK")
      exit_discard
    when /fatal: Entry '(.+)' not uptodate\. Cannot merge\./
      response = TextMate::UI.alert(:informational, "Conflict detected if you switch", "There are uncommitted changes that will cause conflicts by this switch (#{$1}).\nSwitch anyways?", "No", "Yes")
      if response=="Yes"
        output = command("checkout", "-m", target_branch)
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
  
  def run_switch_remote(target)
    remote_alias, remote_branch_name = target.split("/")
    
    repeat = false
    begin
      new_branch_name = TextMate::UI.request_string(:title => "Switch to remote branch", :prompt => "You must set up a local tracking branch to work on '#{target}'.\nWhat would you like to name the local tracking branch?", :default => remote_branch_name)
      new_branch_name = new_branch_name.to_s.strip
      if new_branch_name.blank?
        return exit_discard
      end
      
      if branch_names(:local).include?(new_branch_name)
        response = TextMate::UI.alert(:warning, "Branch name already taken!", "The branch name you have chosen is already in use.\nPlease choose another name, or cancel.", "Cancel", "OK")
        return exit_discard if response == "Cancel"
        repeat = true
      end
    end while repeat
    
    output = command("branch", new_branch_name, target)
    puts htmlize(output)
    run_switch_local(new_branch_name)
  end
  
  def run_delete
    locals = branch_names(:local)
    remotes = branch_names(:remote)
    current = current_branch
    
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
        run_delete_remote(target)
      elsif 
        run_delete_local(target)
      end
    end
  end
  
  def run_delete_local(target)
    output = command("branch", "-d", target).strip
    if output == "Deleted branch #{target}."
      TextMate::UI.alert(:informational, "Success", output, 'OK') 
    elsif output.match(/error.+not a strict subset/)
      response = TextMate::UI.alert(:warning, "Warning", "Branch '#{target}' is not a strict subset of your current HEAD (it has unmerged changes)\nReally delete it?", 'Yes', 'No') 
      return false if response != 'Yes'
      
      output = command("branch", "-D", target).strip
      TextMate::UI.alert(:informational, "Delete branch", output, 'OK')
    else
      response = TextMate::UI.alert(:warning, "Hmmm", "I didn't understand's git's response, perhaps you can make sense of it?\n#{output}", 'Ok') 
    end
    
    true
  end
  
  def run_delete_remote(target)
    # detect remote
    remote_alias, branch = target.split("/")
    output = command("push", remote_alias, ":#{branch}")
    case output
    when /refs\/heads\/#{branch}: .+\-\> deleted/
      TextMate::UI.alert(:informational, "Success", "Deleted remote branch #{target}.", "OK")
      return true
    when /error: dst refspec #{remote_alias} does not match any existing ref on the remote and does not start with refs\/./
      TextMate::UI.alert(:warning, "Delete branch failed!", "The source '#{remote_alias}' reported that the branch '#{branch}' does not exist.\nTry running the prune remote stale branches command?", "OK")
      
    else
      TextMate::UI.alert(:informational, "Deleted remote branch", "I couldn't make sense of this.  Perhaps you can?\n#{output}", 'OK')
    end
  end
end