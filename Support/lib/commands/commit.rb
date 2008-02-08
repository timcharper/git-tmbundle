class SCM::Git::Commit
  include SCM::Git::CommonCommands
  CW = ENV['TM_SUPPORT_PATH'] + '/bin/CommitWindow.app/Contents/MacOS/CommitWindow'
  
  
  def initialize
    @paths = paths
    @base  = nca
    Dir.chdir(@base)
  end

  def status(*args)
    SCM::Git::Status.new.status(*args)
  end
  
  def clean_directory?
    statuses.empty?
  end
  
  def run
    puts "<h1>Committing Files in ‘#{htmlize(shorten(@base))}’</h1>"
    STDOUT.flush
    
    files, status = [], []
    
    statuses.each do |e|
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
      
      puts "add_files - #{add_files.inspect}"
      puts "remove_files - #{remove_files.inspect}"
      res = add(add_files) unless add_files.empty?
      res = rm(remove_files) unless remove_files.empty?
      res = commit(msg)
      puts "<pre>#{htmlize(res)}</pre>"
    end
  end
  
  def statuses
    @statuses ||= status(@paths)
  end
  
  def commit(msg, files = ["."])
    command("commit", "-m", msg, *files)
  end
    
  def add(files = ["."])
    command("add", *files)
  end
  
  def rm(files = ["."])
    command("rm", *files)
  end
  

end

