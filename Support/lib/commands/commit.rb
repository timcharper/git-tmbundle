class SCM::Git::Commit
  include SCM::Git::CommonCommands
  
  GIT_SCM_STATUS_MAP = {
    'A' => {:short => 'A', :long => 'added',        :foreground => '#008000', :background => '#bbffb3'},
    '+' => {:short => '+', :long => 'added',        :foreground => '#008000', :background => '#bbffb3'},
    'D' => {:short => 'D', :long => 'deleted',      :foreground => '#FF0000', :background => '#f59696'},
    'G' => {:short => 'G', :long => 'merged',       :foreground => '#eb6400', :background => '#f7e1ad'},
    'U' => {:short => 'U', :long => 'updated',      :foreground => '#eb6400', :background => '#f7e1ad'},
    'M' => {:short => 'M', :long => 'modified',     :foreground => '#eb6400', :background => '#f7e1ad'},
    'L' => {:short => 'L', :long => 'locked',       :foreground => nil      , :background => nil      },
    'B' => {:short => 'B', :long => 'broken',       :foreground => nil      , :background => nil      },
    'R' => {:short => 'R', :long => 'replaced',     :foreground => '#FF0000', :background => '#f59696'},
    'C' => {:short => 'C', :long => 'conflict',     :foreground => '#008080', :background => '#A3CED0'},
    '!' => {:short => '!', :long => 'missing',      :foreground => '#008080', :background => '#A3CED0'},
    '"' => {:short => '"', :long => 'typeconflict', :foreground => '#008080', :background => '#A3CED0'},
    '?' => {:short => '?', :long => 'unknown',      :foreground => '#800080', :background => '#edaef5'},
    'I' => {:short => 'I', :long => 'ignored',      :foreground => '#800080', :background => '#edaef5'},
    'X' => {:short => 'X', :long => 'external',     :foreground => '#800080', :background => '#edaef5'},
  }
  
  CW = ENV['TM_SUPPORT_PATH'] + '/bin/CommitWindow.app/Contents/MacOS/CommitWindow'
  
  def initialize
    @paths = paths
    @base  = nca
    Dir.chdir(@base)
  end

  def list_files(dir, options = {})
    options[:exclude_file] ||= File.exists?(excl_file = git_dir(dir) + '/info/exclude') ? excl_file : nil
    excl_args = options[:exclude_file] ? " --exclude-from=#{e_sh options[:exclude_file]}" : ''
    options[:type] ||= nil
    type_arg = options[:type] && "-#{options[:type]}"
     %x{#{e_sh git} ls-files #{type_arg} --exclude-per-directory=.gitignore#{excl_args}}.split("\n")
  end

  def status(files_or_dirs = nil, options = {})
    command("reset")

    files_or_dirs = paths if files_or_dirs.nil?
    base_dir = nca(files_or_dirs)
    
    file_statuses = {}
    
    files_or_dirs.each do |file_or_dir|
      dir = dir_part(file_or_dir)
      Dir.chdir(dir)
      
      res = []
      [['o', '?'], ['d', 'D'], ['m', 'M']].each do |file_type, display_status|
        res << list_files(file_or_dir, :type => file_type).map { |e| file_statuses[File.expand_path(e, dir)] ||= display_status }
      end
    end
    
    file_statuses.sort.map do |filepath, display_status|
      {:path => filepath, :display => shorten(filepath, base_dir), :status => GIT_SCM_STATUS_MAP[display_status]}
    end
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
      res = commit(msg, files)
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

