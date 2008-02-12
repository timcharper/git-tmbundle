require ENV['TM_SUPPORT_PATH'] + '/lib/ui.rb'

class SCM::Git::Pull < SCM::Git
    
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
    sources_with_default = [branch_default_source] + (sources_with_default - [branch_default_source]) if branch_default_source
    
    f.layout do
      TextMate::UI.request_item(:title => "Push", :prompt => "Pull from where?", :items => sources_with_default) do |source|
        # check to see if the branch has a pull source set up.  if not, prompt them for which branch to pull from
        if source != branch_default_source || branch_default_merge.nil?
          # select a branch to merge from
          remote_branches = branches(:remote, :remote_name => source).map{|b| b[:name]}
          remote_branch = TextMate::UI.request_item(:title => "Branch to merge from?", :prompt => "The config doesn't tell me which remote branch to grab changes from.  Please select a branch:", :items => remote_branches)
          if remote_branch.nil?
            puts "Aborted"
            abort
          end
          
          if TextMate::UI.alert(:warning, "Setup automerge for these branches?", "Would you like me to tell git to always merge #{remote_branch} to #{c_branch}?", 'Yes', 'No')  == "Yes"
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
    state = nil
    branch = nil
    callbacks[:deltifying] ||= {}
    callbacks[:writing] ||= {}
    
    line = ""
    stream.each_byte do |char|
      char = [char].pack('c')
      line << char
      next unless char=="\n" || char=="\r"
      # puts "line read: #{line.inspect}<br/>"
      case line
      when /^Already up\-to\-date/
        output[:nothing_to_pull] = true
      when /(Unpacking) ([0-9]+) objects/
        state = $1
        callbacks[:start] && callbacks[:start].call(state, $2.to_i)
        percentage, index, count = 0, 0, $2.to_i
      when /([0-9]+)% \(([0-9]+)\/([0-9]+)\) done/
        percentage, index, count = $1.to_i, $2.to_i, $3.to_i
      when /^\* ([^:]+):/
        branch = $1
      when /^  (old\.\.new|commit): (.+)/
        revs = $2.split("..")
        revs = ["#{revs[0]}^", revs[0]] if revs.length == 1
        output[:pulls][branch] = revs
      end
      
      output[:text] << line
      
      if state
        callbacks[:progress] && callbacks[:progress].call(state, percentage, index, count)
        if percentage == 100
          callbacks[:end] && callbacks[:end].call(state, count)
          state = nil 
        end
      end
      line=""
    end
    output
  end
end
