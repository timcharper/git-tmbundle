require ENV['TM_SUPPORT_PATH'] + '/lib/ui.rb'

class RemoteController < ApplicationController
  ALL_REMOTES = "...all remotes..."
  
  include SubmoduleHelper::Update
  
  before_filter :set_script_at_top
  def set_script_at_top
    @script_at_top = true
  end
  
  def fetch
    branch = git.branch.current_branch
    branch_remote = branch && branch_remote
    
    for_each_selected_remote(:title => "Fetch", :prompt => "Fetch from which shared repository?", :items => git.remotes, :default => branch.remote) do |remote|
      puts "<h2>Fetching from #{remote}</h2>"
      output = run_fetch(remote)
      puts htmlize(output[:text])
      
      unless output[:fetches].empty?
        puts("<h2>Log of changes fetched</h2>")
        output_branch_logs(output[:fetches])
      end
      
      puts "<h2>Pruning stale branches from #{remote}</h2>"
      puts git.command('remote', 'prune', remote)
      puts "<p>Done.</p>"
    end
  end
  
  def pull
    if (branch = git.branch.current_branch).nil?
      puts "You can't pull while not being on a branch (and you are not on a branch).  Please switch to a branch, and try again."
      output_show_html and return
    end
    
    remotes = git.remotes.with_this_at_front(branch.remote)
    
    TextMate::UI.request_item(:title => "Push", :prompt => "Pull from where?", :items => remotes) do |remote|
      # check to see if the branch has a pull remote set up.  if not, prompt them for which branch to pull from
      if (remote != branch.remote) || branch.merge.nil?
        # select a branch to merge from
        remote_branch_name = setup_auto_merge(remote, branch)
        return false unless remote_branch_name
      end
      
      puts "<p>Pulling from remote source '#{remote}'\n</p>"
      
      with_submodule_cacheing do
        output = run_pull(remote, remote_branch_name)
        puts "<pre>#{output[:text]}</pre>"
      
        if ! output[:pulls].empty?
          puts("<h2>Log of changes pulled</h2>")
          output_branch_logs(output[:pulls])
          true
        elsif output[:nothing_to_pull]
          puts "Nothing to pull"
          false
        end
      end
    end
  end
  
  def push
    current_name = git.branch.current.name
    for_each_selected_remote(:title => "Push", :prompt => "Select a remote source to push the branch #{current_name} to:", :items => git.remotes) do |remote|
      puts "<p>Pushing to remote source '#{remote}'\n</p>"
      display_push_output(run_push(remote, :branch => current_name))
    end
  end
  
  def push_tag
    tag = params[:tag] || (raise "select tag not yet implemented")
    for_each_selected_remote(:title => "Push", :prompt => "Select a remote source to push the tag #{tag} to:", :items => git.remotes) do |remote|
      puts "<p>Pushing tag #{tag} to '#{remote}'\n</p>"
      display_push_output(run_push(remote, :tag => tag))
    end
  end
  
  protected
    def setup_auto_merge(remote, branch)
      remote_branches = git.branch.list_names(:remote, :remote => remote ).with_this_at_front(/(\/|^)#{branch.name}$/)
      remote_branch_name = TextMate::UI.request_item(:title => "Branch to merge from?", :prompt => "Merge which branch to '#{branch.name}'?", :items => remote_branches, :force_pick => true)
      if remote_branch_name.nil? || remote_branch_name.empty?
        puts "Aborted"
        return nil
      end

      if TextMate::UI.alert(:warning, "Setup automerge for these branches?", "Would you like me to tell git to always merge:\n #{remote_branch_name} -> #{branch.name}?", 'Yes', 'No')  == "Yes"
        branch.remote = remote
        branch.merge = "refs/heads/" + remote_branch_name.split("/").last
      end
      remote_branch_name
    end
    
    def display_push_output(output)
      flush
      if ! output[:pushes].empty?
        puts "<pre>#{output[:text]}</pre>"
        output_branch_logs(output[:pushes])
      elsif output[:nothing_to_push]
        puts "There's nothing to push!"
        puts output[:text]
      else
        puts "<h3>Output:</h3>"
        puts "<pre>#{output[:text]}</pre>"
      end
    end
    
    def output_branch_logs(branch_revisions_hash = {})
      branch_revisions_hash.each do |branch_name, revisions|
        puts "<h2>Branch '#{branch_name}': #{short_rev(revisions.first)}..#{short_rev(revisions.last)}</h2>"
        render_component(:controller => "log", :action => "log", :path => ".", :revisions => [revisions.first, revisions.last])
      end
    end
    
    def run_pull(remote, remote_branch_name)
      flush
      pulls = git.pull(remote, remote_branch_name,
        :start => lambda { |state, count| progress_start(remote, state, count) }, 
        :progress => lambda { |state, percentage, index, count| progress(remote, state, percentage, index, count)},
        :end => lambda { |state, count| progress_end(remote, state, count) }
      )
      rescan_project
      pulls
    end
    
    def run_push(remote, options = {})
      flush
      git.push(remote, options.merge(
        :start => lambda { |state, count| progress_start(remote, state, count) }, 
        :progress => lambda { |state, percentage, index, count| progress(remote, state, percentage, index, count)},
        :end => lambda { |state, count| progress_end(remote, state, count) }
      ))
    end
    
    def run_fetch(remote)
      flush
      git.fetch(remote,
        :start => lambda { |state, count| progress_start(remote, state, count) }, 
        :progress => lambda { |state, percentage, index, count| progress(remote, state, percentage, index, count)},
        :end => lambda { |state, count| progress_end(remote, state, count) }
      )
    end
    
    def progress_start(remote, state, count)
      puts("<div>#{remote}_#{state} #{count} objects.  <span id='#{state}_progress'>0% 0 / #{count}</span></div>")
    end
    
    def progress(remote, state, percentage, index, count)
      puts <<-EOF
      <script language='JavaScript'>
        $('#{remote}_#{state}_progress').update('#{percentage}% #{index} / #{count}')
      </script>
      EOF
      
      flush 
    end
    
    def progress_end(remote, state, count)
      puts <<-EOF
      <script language='JavaScript'>
        $('#{remote}_#{state}_progress').update('Done')
      </script>
      EOF
      flush
    end
    
    def for_each_selected_remote(options, &block)
      options = {:title => "Select remote", :prompt => "Select a remote...", :force_pick => true}.merge(options)
      default = options.delete(:default)
      remotes = options[:items]
      if default
        remotes.unshift(default)
        remotes.uniq!
      end
      
      remotes << ALL_REMOTES if remotes.length > 1
      TextMate::UI.request_item(options) do |selections|
        ((selections == ALL_REMOTES) ? (remotes-[ALL_REMOTES]) : [selections]).each do |selection|
          yield selection
        end
      end
    end
end

