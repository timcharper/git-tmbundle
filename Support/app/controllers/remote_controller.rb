require ENV['TM_SUPPORT_PATH'] + '/lib/ui.rb'

class RemoteController < ApplicationController
  ALL_REMOTES = "...all remotes..."
  
  before_filter :set_script_at_top
  def set_script_at_top
    @script_at_top = true
  end
  
  def fetch
    branch = git.branch.current_branch
    config_key = "branch.#{branch.name}.remote"
    
    for_each_selected_remote(:title => "Fetch", :prompt => "Fetch from which shared repository?", :items => git.sources, :default => branch.remote) do |source|
      puts "<h2>Fetching from #{source}</h2>"
      flush
      result = git.fetch(source)
      puts htmlize(result[:text])
      puts "<p>Done.</p>"
    end
  end
  
  def pull
    branch = git.branch.current_branch
    sources = git.sources
    sources = ([branch.remote] + sources).uniq if branch.remote
    
    TextMate::UI.request_item(:title => "Push", :prompt => "Pull from where?", :items => sources) do |source|
      # check to see if the branch has a pull source set up.  if not, prompt them for which branch to pull from
      if (source != branch.remote) || branch.merge.nil?
        # select a branch to merge from
        remote_branches = git.branch.list_names(:remote)
        # by default, select a branch with the same name first
        remote_branches = (remote_branches.grep(/(\/|^)#{branch.name}$/) + remote_branches).uniq
        # hack - make it always prompt (we don't want to just jump the gun and merge the only branch if only one is available... give them the choice)
        remote_branches << ""
        remote_branch_name = TextMate::UI.request_item(:title => "Branch to merge from?", :prompt => "Merge which branch to '#{branch.name}'?", :items => remote_branches)
        if remote_branch_name.nil? || remote_branch_name.empty?
          puts "Aborted"
          return
        end
        
        if TextMate::UI.alert(:warning, "Setup automerge for these branches?", "Would you like me to tell git to always merge:\n #{remote_branch_name} -> #{branch.name}?", 'Yes', 'No')  == "Yes"
          branch.remote = source
          branch.merge = "refs/heads/" + remote_branch_name.split("/").last
        end
      end
      
      puts "<p>Pulling from remote source '#{source}'\n</p>"
      flush
      output = git.pull(source, remote_branch_name,
        :start => lambda { |state, count| progress_start(state, count) }, 
        :progress => lambda { |state, percentage, index, count| progress(state, percentage, index, count)},
        :end => lambda { |state, count| progress_end(state, count) }
      )
      rescan_project
      puts "<pre>#{output[:text]}</pre>"
      
      if ! output[:pulls].empty?
        puts("<h2>Log of changes pulled</h2>")
        output[:pulls].each do |branch_name, revisions|
          puts "<h2>Branch '#{branch_name}': #{short_rev(revisions.first)}..#{short_rev(revisions.last)}</h2>"
          render_component(:controller => "log", :action => "log", :path => ".", :revisions => [revisions.first, revisions.last])
        end
      elsif output[:nothing_to_pull]
      else
        puts "<h3>Error</h3>"
      end
    end
  end
  
  def push
    for_each_selected_remote(:title => "Push", :prompt => "Select a remote source to push to:", :items => git.sources) do |name|
      puts "<p>Pushing to remote source '#{name}'\n</p>"
      flush
      output = git.push(name, 
        :start => lambda { |state, count| progress_start(state, count) }, 
        :progress => lambda { |state, percentage, index, count| progress(state, percentage, index, count)},
        :end => lambda { |state, count| progress_end(state, count) }
      )
      
      if ! output[:pushes].empty?
        puts "<pre>#{output[:text]}</pre>"
        
        output[:pushes].each do |branch_name, revisions|
          puts "<h2>Branch '#{branch_name}': #{short_rev(revisions.first)}..#{short_rev(revisions.last)}</h2>"
          render_component(:controller => "log", :action => "log", :path => ".", :revisions => [revisions.first, revisions.last])
        end
      elsif output[:nothing_to_push]
        puts "There's nothing to push!"
        puts output[:text]
      else
        puts "<h3>Error:</h3>"
        puts "<pre>#{output[:text]}</pre>"
      end
    end
  end
  
  protected
    
    def progress_start(state, count)
      puts("<div>#{state} #{count} objects.  <span id='#{state}_progress'>0% 0 / #{count}</span></div>")
    end
    
    def progress(state, percentage, index, count)
      puts <<-EOF
      <script language='JavaScript'>
        $('#{state}_progress').update('#{percentage}% #{index} / #{count}')
      </script>
      EOF
      
      flush 
    end
    
    def progress_end(state, count)
      puts <<-EOF
      <script language='JavaScript'>
        $('#{state}_progress').update('Done')
      </script>
      EOF
      flush
    end
    
    def for_each_selected_remote(options, &block)
      options = {:title => "Select remote", :prompt => "Select a remote..."}.merge(options)
      default = options.delete(:default)
      sources = options[:items]
      if default
        sources.unshift(default)
        sources.uniq!
      end
      
      sources << ALL_REMOTES if sources.length > 1
      TextMate::UI.request_item(options) do |selections|
        ((selections == ALL_REMOTES) ? (sources-[ALL_REMOTES]) : [selections]).each do |selection|
          yield selection
        end
      end
    end
end