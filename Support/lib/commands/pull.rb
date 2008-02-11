require ENV['TM_SUPPORT_PATH'] + '/lib/ui.rb'

class SCM::Git::Pull
  include SCM::Git::CommonCommands
  
  def initialize
    Dir.chdir(git_base)
  end
  
  # def run
  #   TextMate::UI.request_item(:title => "Pull", :prompt => "Select a remote source to pull from:", :items => sources) do |name|
  #     puts "<p>Pulling from remote source '#{name}'\n</p>"
  #     flush
  #     puts htmlize(pull(name))
  #   end
  # end

  def run
    f = Formatters::Pull.new
    
    f.layout do
      TextMate::UI.request_item(:title => "Push", :prompt => "Select a remote source to pull from:", :items => sources) do |name|
        puts "<p>Pulling from remote source '#{name}'\n</p>"
        flush
        output = pull(name, 
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
  
  def pull(source, callbacks = {})
    args = ["pull", source]
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
