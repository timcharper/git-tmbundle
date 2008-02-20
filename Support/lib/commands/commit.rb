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
    if File.exist?(File.join(git_base, ".git/MERGE_HEAD"))
      run_merge_commit
    else
      run_partial_commit
    end
  end
  
  def run_merge_commit
    f = Formatters::Commit.new
    f.layout do
      f.header "Resolve a merge conflict"
    
      status = Git::Status.new
      status.run([git_base])
      # puts statuses(git_base).inspect
      if statuses(git_base).any? {|status_options| status_options[:status][:short] == "C"}
        puts "<p>You still have outstanding merge conflicts.  Resolve them, and try to commit again.</p>"
        abort
      end
      f.commit_merge_dialog(File.read(File.join(git_base, ".git/MERGE_MSG")))
    end
  end
  
  def run_partial_commit
    f = Formatters::Commit.new
    target_file_or_dir = paths.first
    f.layout do
      f.header "Committing Files in ‘#{htmlize(shorten(target_file_or_dir))}’"
      flush
    
      files, status = [], []
      statuses(target_file_or_dir).each do |e|
        files  << e_sh(shorten(e[:path], @base))
        status << e_sh(e[:status][:short])
      end

      res = %x{#{e_sh CW}                 \
        --diff-cmd   '#{git},diff'        \
        --status #{status.join ':'}       \
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
        auto_add_rm(files)
        res = commit(msg, files)
        f.output_commit_result(res)
      end
    end
  end
  
  def auto_add_rm(files)
    chdir_base
    add_files = files.select{ |f| File.exists?(f) }
    remove_files = files.reject{ |f| File.exists?(f) }
    res = add(add_files) unless add_files.empty?
    res = rm(remove_files) unless remove_files.empty?
  end
  
  def statuses(path = paths.first)
    status(path)
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

