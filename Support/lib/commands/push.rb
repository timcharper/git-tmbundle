require ENV['TM_SUPPORT_PATH'] + '/lib/ui.rb'

class SCM::Git::Push < SCM::Git
  
  def initialize
    @base = git_base
    Dir.chdir(@base)
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
          puts output[:text]
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
    state = nil
    callbacks[:deltifying] ||= {}
    callbacks[:writing] ||= {}
    
    line = ""
    stream.each_byte do |char|
      char = [char].pack('c')
      line << char
      next unless char=="\n" || char=="\r"
      # puts "line read: #{line.inspect}<br/>"
      case line
      when /^Everything up\-to\-date/
        output[:nothing_to_push] = true
      when /(Deltifying|Writing) ([0-9]+) objects/
        state = $1
        callbacks[:start] && callbacks[:start].call(state, $2.to_i)
        percentage, index, count = 0, 0, $2.to_i
      when /([0-9]+)% \(([0-9]+)\/([0-9]+)\) done/
        percentage, index, count = $1.to_i, $2.to_i, $3.to_i
      when /^(.+): ([a-f0-9]{40}) \-\> ([a-f0-9]{40})/
        state = nil
        output[:pushes][$1] = [$2,$3]
      else
        output[:text] << line
      end
      
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