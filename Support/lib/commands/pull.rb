require ENV['TM_SUPPORT_PATH'] + '/lib/ui.rb'
require File.dirname(__FILE__) + "/../stream_progress_methods.rb"

class SCM::Git::Pull < SCM::Git
  include StreamProgressMethods
  def initialize
    chdir_base
  end

  def run
    f = Formatters::Pull.new
    c_branch = current_branch
    branch_remote_config_key = "branch.#{c_branch}.remote"
    branch_remote_merge_key = "branch.#{c_branch}.merge"
    branch_default_source = self[branch_remote_config_key]
    branch_default_merge = self[branch_remote_merge_key]
    sources_with_default = sources
    sources_with_default = ([branch_default_source] + sources_with_default).uniq if branch_default_source
    
    f.layout do
      TextMate::UI.request_item(:title => "Push", :prompt => "Pull from where?", :items => sources_with_default) do |source|
        # check to see if the branch has a pull source set up.  if not, prompt them for which branch to pull from
        if source != branch_default_source || branch_default_merge.nil?
          # select a branch to merge from
          remote_branches = branches(:remote, :remote_name => source).map{|b| b[:name]}
          # by default, select a branch with the same name first
          remote_branches = (remote_branches.grep(/(\/|^)#{c_branch}$/) + remote_branches).uniq
          # hack - make it always prompt (we don't want to just jump the gun and merge the only branch if only one is available... give them the choice)
          remote_branches << ""
          remote_branch = TextMate::UI.request_item(:title => "Branch to merge from?", :prompt => "Merge which branch to '#{c_branch}'?", :items => remote_branches)
          if remote_branch.nil? || remote_branch.empty?
            puts "Aborted"
            abort
          end
          
          if TextMate::UI.alert(:warning, "Setup automerge for these branches?", "Would you like me to tell git to always merge:\n #{remote_branch} -> #{c_branch}?", 'Yes', 'No')  == "Yes"
            self[branch_remote_config_key] = source
            self[branch_remote_merge_key] = "refs/heads/" + remote_branch.split("/").last
          end
        end
        
        puts "<p>Pulling from remote source '#{source}'\n</p>"
        flush
        output = pull(source, remote_branch,
          :start => lambda { |state, count| f.progress_start(state, count) }, 
          :progress => lambda { |state, percentage, index, count| f.progress(state, percentage, index, count)},
          :end => lambda { |state, count| f.progress_end(state, count) }
        )
        
        puts "<pre>#{output[:text]}</pre>"
        
        if ! output[:pulls].empty?
          log = SCM::Git::Log.new
          log_f = Formatters::Log.new
          log_f.header("Log of changes pulled")
          output[:pulls].each do |branch, revisions|
            log_f.sub_header("Branch '#{branch}': #{short_rev(revisions.first)}..#{short_rev(revisions.last)}")
            log_f.content log.log(".", :revisions => [revisions.first, revisions.last], :with_log => true)
          end
        elsif output[:nothing_to_pull]
        else
          puts "<h3>Error:</h3>"
        end
      end
    end
  end
  
  def pull(source, remote_merge_branch = nil, callbacks = {})
    args = ["pull", source]
    args << remote_merge_branch.split('/').last if remote_merge_branch
    p = popen_command(*args)
    process_pull(p, callbacks)
  end
  
  def process_pull(stream, callbacks = {})
    output = {:pulls => {}, :text => "", :nothing_to_pull => false}
    branch = nil
    
    process_with_progress(stream, :callbacks => callbacks, :start_regexp => /(Unpacking) ([0-9]+) objects/) do |line|
      case line
      when /^Already up\-to\-date/          then output[:nothing_to_pull] = true
      when /^\* ([^:]+):/                   then branch = $1
      when /^  (old\.\.new|commit): (.+)/   then output[:pulls][branch] = get_rev_range($2)
      end
      
      output[:text] << line
    end
    output
  end
end
