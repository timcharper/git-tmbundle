# encoding: utf-8

require ENV['TM_SUPPORT_PATH'] + '/lib/ui.rb'

class RemoteController < ApplicationController
  ALL_REMOTES = "...all remotes..."
  
  include SubmoduleHelper::Update
  include SubmoduleHelper
  
  
  before_filter :set_script_at_top
  def set_script_at_top
    @script_at_top = true
  end
  
  def fetch
    if (branch = git.branch.current) && (remote = branch.remote)
      default_remote = remote.name
    else
      default_remote = git.remote.names.with_this_at_front("origin").first
    end
    
    for_each_selected_remote(:title => "Fetch", :prompt => "Fetch from which shared repository?", :items => git.remote.names, :default => default_remote) do |remote_name|
      puts "<h2>Fetching from #{remote_name}</h2>"
      output = run_fetch(remote_name)
      puts htmlize(output[:text])
      
      unless output[:fetches].empty?
        puts("<h2>Log of changes fetched</h2>")
        output_branch_logs(git, output[:fetches])
      end
      
      puts "<h2>Pruning stale branches from #{remote_name}</h2>"
      puts git.command('remote', 'prune', remote_name)
      puts "<p>Done.</p>"
    end
  end
  
  def pull
    if (branch = git.branch.current).nil?
      puts "You can't pull while not being on a branch (and you are not on a branch).  Please switch to a branch, and try again."
      output_show_html and return
    end
    
    remote_names = git.remote.names.with_this_at_front(branch.remote_name)
    
    TextMate::UI.request_item(:title => "Push", :prompt => "Pull from where?", :items => remote_names) do |remote_name|
      # check to see if the branch has a pull remote set up.  if not, prompt them for which branch to pull from
      if (remote_name != branch.remote_name) || branch.merge.nil?
        # select a branch to merge from
        remote_branch_name = setup_auto_merge(remote_name, branch)
        return false unless remote_branch_name
      else
        remote_branch_name = branch.merge
      end
      
      puts "<p>Pulling from remote source ‘#{remote_name}’ on branch ‘#{branch.name}’</p>"
      
      with_submodule_updating do
        output = run_pull(remote_name, remote_branch_name)
        puts "<pre>#{output[:text]}</pre>"
      
        if ! output[:pulls].empty?
          puts("<h2>Log of changes pulled</h2>")
          output_branch_logs(git, output[:pulls])
          true
        elsif output[:nothing_to_pull]
          puts "Nothing to pull"
          false
        end
      end
    end
  end
  
  def push
    if (branch = git.branch.current).nil?
      puts "You can't push the current branch while not being on a branch (and you are not on a branch).  Please switch to a branch, and try again."
      output_show_html and return
    end
    
    current_name = branch.name
    for_each_selected_remote(:title => "Push", :prompt => "Select a remote source to push the branch #{current_name} to:", :items => git.remote.names) do |remote_name|
      puts "<p>Pushing to remote source '#{remote_name}' for branch '#{current_name}'</p>"
      display_push_output(git, run_push(git, remote_name, :branch => current_name))
      
      git.submodule.all.each do |submodule|
        next unless (current_branch = submodule.git.branch.current) && (current_branch.tracking_branch_name)
        case current_branch.tracking_status
        when :ahead
          render_submodule_header(submodule)
          display_push_output(submodule.git, run_push(submodule.git, current_branch.remote_name, :branch => current_branch.name))
        when :diverged
          puts "<p>Can't push submodule '#{submodule.name}' - you need to pull first</p>"
        end
      end
    end
  end
  
  def push_tag
    tag = params[:tag] || (raise "select tag not yet implemented")
    for_each_selected_remote(:title => "Push", :prompt => "Select a remote source to push the tag #{tag} to:", :items => git.remote.names) do |remote_name|
      puts "<p>Pushing tag #{tag} to '#{remote_name}'\n</p>"
      display_push_output(git, run_push(git, remote_name, :tag => tag))
    end
  end
  
  protected
    def setup_auto_merge(remote_name, branch)
      remote_branches = git.branch.list_names(:remote, :remote => remote_name ).with_this_at_front(/(\/|^)#{branch.name}$/)
      remote_branch_name = TextMate::UI.request_item(:title => "Branch to merge from?", :prompt => "Merge which branch to '#{branch.name}'?", :items => remote_branches, :force_pick => true)
      if remote_branch_name.nil? || remote_branch_name.empty?
        puts "Aborted"
        return nil
      end

      if TextMate::UI.alert(:warning, "Setup automerge for these branches?", "Would you like me to tell git to always merge:\n #{remote_branch_name} -> #{branch.name}?", 'Yes', 'No')  == "Yes"
        branch.remote_name = remote_name
        branch.merge = "refs/heads/" + remote_branch_name.split("/").last
      end
      remote_branch_name
    end
    
    def display_push_output(git, output)
      flush
      sleep(0.2) # this small delay prevents TextMate from garbling the HTML
      if ! output[:pushes].empty?
        puts "<pre>#{output[:text]}</pre>"
        output_branch_logs(git, output[:pushes])
        flush
      elsif output[:nothing_to_push]
        puts "Nothing to push."
        puts "<pre>#{output[:text]}</pre><br/>"
        flush
      else
        puts "<h3>Output:</h3>"
        puts "<pre>#{output[:text]}</pre>"
        flush
      end
    end
    
    def output_branch_logs(git, branch_revisions_hash = {})
      branch_revisions_hash.each do |branch_name, revisions|
        puts "<h2>Branch '#{branch_name}': #{short_rev(revisions.first)}..#{short_rev(revisions.last)}</h2>"
        render_component(:controller => "log", :action => "log", :path => ".", :git_path => git.path, :revisions => [revisions.first, revisions.last])
      end
    end
    
    def run_pull(remote_name, remote_branch_name)
      flush
      pulls = git.pull(remote_name, remote_branch_name,
        :start => lambda { |state, count| progress_start(remote_name, state, count) }, 
        :progress => lambda { |state, percentage, index, count| progress(remote_name, state, percentage, index, count)},
        :end => lambda { |state, count| progress_end(remote_name, state, count) }
      )
      rescan_project
      pulls
    end
    
    def run_push(git, remote_name, options = {})
      flush
      git.push(remote_name, options.merge(
        :start => lambda { |state, count| progress_start(remote_name, state, count) }, 
        :progress => lambda { |state, percentage, index, count| progress(remote_name, state, percentage, index, count)},
        :end => lambda { |state, count| progress_end(remote_name, state, count) }
      ))
    end
    
    def run_fetch(remote_name)
      flush
      git.fetch(remote_name,
        :start => lambda { |state, count| progress_start(remote_name, state, count) }, 
        :progress => lambda { |state, percentage, index, count| progress(remote_name, state, percentage, index, count)},
        :end => lambda { |state, count| progress_end(remote_name, state, count) }
      )
    end
    
    def progress_start(remote_name, state, count)
      puts("<div>#{state} #{count} objects.  <span id='#{remote_name}_#{state}_progress'>0% 0 / #{count}</span></div>")
    end
    
    def progress(remote_name, state, percentage, index, count)
      puts <<-EOF
      <script type='text/javascript'>
        $('#{remote_name}_#{state}_progress').update('#{percentage}% #{index} / #{count}')
      </script>
      EOF
      
      flush 
    end
    
    def progress_end(remote_name, state, count)
      puts <<-EOF
      <script type='text/javascript'>
        $('#{remote_name}_#{state}_progress').update('Done')
      </script>
      EOF
      flush
    end
    
    def for_each_selected_remote(options, &block)
      options = {:title => "Select remote", :prompt => "Select a remote...", :force_pick => true}.merge(options)
      default = options.delete(:default)
      remote_names = options[:items]
      if default
        remote_names.unshift(default)
        remote_names.uniq!
      end
      
      remote_names << ALL_REMOTES if remote_names.length > 1
      TextMate::UI.request_item(options) do |selections|
        ((selections == ALL_REMOTES) ? (remote_names-[ALL_REMOTES]) : [selections]).each do |selection|
          yield selection
        end
      end
    end
end

