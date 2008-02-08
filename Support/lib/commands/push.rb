require ENV['TM_SUPPORT_PATH'] + '/lib/ui.rb'

class SCM::Git::Push
  include SCM::Git::CommonCommands
  
  def initialize
    @base = git_base
    Dir.chdir(@base)
  end
  
  def run
    TextMate::UI.request_item(:title => "Push", :prompt => "Select a remote source to push to:", :items => sources) do |name|
      puts "<p>Pushing to remote source '#{name}'\n</p>"
      flush
      puts htmlize(push(name))
    end
  end
  
  def push(source, callbacks = {})
    args = ["push", source]
    if callbacks.empty?
      p = popen(command_str(*args))
      process_push(p, callbacks)
      true
    else
      command(*args)
    end
  end
  
  def process_push(stream, callbacks = {})
    output = {:pushes => {}, :text => ""}
    state = nil
    
    while !stream.eof
      input = stream.read
      input.split("\n").each do |line|
        output[:text] << "#{line}\n"
        case line
        when /Deltifying [0-9]+ objects/
          state = :deltifying
        when /Writing [0-9]+ objects/
          state = :writing
        when /^(.+): ([a-f0-9]{40}) \-\> ([a-f0-9]{40})/
          state = nil
          output[:pushes][$1] = [$2,$3]
        end
        
        case state
        when :deltifying
          case line
          when /Deltifying ([0-9]+) objects/
            count = $1.to_i
            percentage = 0
            index = 0
          when /([0-9]+)% \(([0-9]+)\/([0-9]+)\) done/
            percentage = $1.to_i
            count = $3.to_i
            index = $2.to_i
          end
          callbacks[:deltifying] && callbacks[:deltifying].call(percentage, index, count)
          state = nil if percentage == 100
        when :writing
          case line
          when /Writing ([0-9]+) objects/
            count = $1.to_i
            percentage = 0
            index = 0
          when /([0-9]+)% \(([0-9]+)\/([0-9]+)\) done/
            percentage = $1.to_i
            count = $3.to_i
            index = $2.to_i
          end
          callbacks[:writing] && callbacks[:writing].call(percentage, index, count)
          state = nil if percentage == 100
        else
        end
        
        
      end
    end
    output
  end
end