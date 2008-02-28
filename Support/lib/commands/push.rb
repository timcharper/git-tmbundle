require ENV['TM_SUPPORT_PATH'] + '/lib/ui.rb'
require File.dirname(__FILE__) + "/../stream_progress_methods.rb"

class SCM::Git::Push < SCM::Git
  include StreamProgressMethods
  
  def initialize
    @base = git_base
    chdir_base
  end
  
  def run
    f = Formatters::Push.new
    
    f.layout do
      TextMate::UI.request_item(:title => "Push", :prompt => "Select a remote source to push to:", :items => sources) do |name|
        puts "<p>Pushing to remote source '#{name}'\n</p>"
        flush
        output = push(name, 
          :start => lambda { |state, count| f.progress_start(state, count) }, 
          :progress => lambda { |state, percentage, index, count| f.progress(state, percentage, index, count)},
          :end => lambda { |state, count| f.progress_end(state, count) }
        )
      
        if ! output[:pushes].empty?
          log = SCM::Git::Log.new
          log_f = Formatters::Log.new
          puts "<pre>#{output[:text]}</pre>"
          log_f.header("Log of changes pushed")
          output[:pushes].each do |branch, revisions|
            log_f.sub_header("Branch '#{branch}': #{short_rev(revisions.first)}..#{short_rev(revisions.last)}")
            log_f.content log.log(".", :revisions => [revisions.first, revisions.last], :with_log => true)
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
  end
  
  def push(source, callbacks = {})
    args = ["push", source]
    p = popen_command(*args)
    process_push(p, callbacks)
  end
  
  def process_push(stream, callbacks = {})
    output = {:pushes => {}, :text => "", :nothing_to_push => false}
    branch = nil
    
    process_with_progress(stream, :callbacks => callbacks, :start_regexp => /(?-:remote: )?(Deltifying|Writing) ([0-9]+) objects/) do |line|
      case line
      when /(?-:remote: )?^Everything up\-to\-date/
        output[:nothing_to_push] = true
      when /(?-:remote: )?^(.+): ([a-f0-9]{40}) \-\> ([a-f0-9]{40})/
        output[:pushes][$1] = [$2,$3]
      when /^ +([0-9a-f]+\.\.[0-9a-f]+) +([^ ]+) +\-\> (.+)$/
        output[:pushes][$2] = get_rev_range($1)

      else
        output[:text] << line
      end
      
    end
    output
  end
end