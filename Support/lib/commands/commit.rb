class SCM::Git::Commit < SCM::Git
  CW = ENV['TM_SUPPORT_PATH'] + '/bin/CommitWindow.app/Contents/MacOS/CommitWindow'
  
  
  def initialize
    @paths = paths
    @base  = git_base
    chdir_base
  end

  def status(*args)
    SCM::Git::Status.new.status(*args)
  end
  
  def clean_directory?
    statuses.empty?
  end
  
  def run
    f = Formatters::Commit.new
    target_file_or_dir = paths.first
    f.header "Committing Files in ‘#{htmlize(shorten(target_file_or_dir))}’"
    
    flush
    f.layout do
    
      files, status = [], []
      statuses(target_file_or_dir).each do |e|
        files  << e_sh(shorten(e[:path], @base))
        status << e_sh(e[:status][:short])
      end

      res = %x{#{e_sh CW}                \
        --diff-cmd   '#{git},diff'          \
        --status #{status.join ':'}      \
        #{files.join ' '} 2>/dev/console
      }

      if $? != 0
        puts "<strong>Cancel</strong>"
        abort
      end

      res   = Shellwords.shellwords(res)
      msg   = res[1]
      files = res[2..-1]

      puts "<h2>Commit Files:</h2><ul>"
      puts files.map { |e| "<li>#{htmlize(e)}</li>\n" }.join
      puts "</ul>"

      puts "<h2>Using Message:</h2>"
      puts "<pre>#{htmlize(msg)}</pre>"
      STDOUT.flush

      unless files.empty?
        puts "<h2>Result:</h2>"
        add_files = files.select{ |f| File.exists?(f) }
        remove_files = files.reject{ |f| File.exists?(f) }
        res = add(add_files) unless add_files.empty?
        res = rm(remove_files) unless remove_files.empty?
        res = commit(msg, files)
        
        puts "<pre>#{htmlize(res[:output])}</pre>"
        
        puts "<h2>Diff of committed changes:</h2>"
        if res[:rev]
          diff_formatter = Formatters::Diff.new
          diff = SCM::Git::Diff.new
          diff_result = diff.diff_revisions(".", "#{res[:rev]}^", "#{res[:rev]}")
          
          diff_formatter.content diff_result
        end
      end
    end
  end
  
  def statuses(path = paths.first)
    @statuses ||= status(path)
  end
  
  def commit(msg, files = ["."])
    parse_commit(command("commit", "-m", msg, *files))
  end
  
  def parse_commit(commit_output)
    result = {:output => ""}
    commit_output.split("\n").each do |line|
      case line
      when /^ *Created commit ([a-f0-9]+): (.*)$/
        result[:rev] = $1
        result[:message] = $2
      when /^ *([0-9]+) files changed, ([0-9]+) insertions\(\+\), ([0-9]+) deletions\(\-\) *$/
        result[:files_changed] = $1.to_i
        result[:insertions] = $2.to_i
        result[:deletions] = $3.to_i
      else
        result[:output] << "#{line}\n"
      end
    end
    result
  end
    
  def add(files = ["."])
    command("add", *files)
  end
  
  def rm(files = ["."])
    command("rm", *files)
  end
  

end

