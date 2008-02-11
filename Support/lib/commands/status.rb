class SCM::Git::Status
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
  
  def initialize
  end
  
  def status(files_or_dirs = nil, options = {})
    files_or_dirs = paths if files_or_dirs.nil?
    base_dir = nca(files_or_dirs)
    
    file_statuses = {}
    
    files_or_dirs.each do |file_or_dir|
      dir = dir_part(file_or_dir)
      Dir.chdir(dir)
      
      res = []
      # a note about the following:
      # the order of these parameter is important.  Deleted files are also listed when querying git ls-files -m.  Therefore, if we list the deleted files first, then add any modified files that weren't listed by delete, we get a less-suprising result (for the commit dialog)
      [['o', '?'], ['d', 'D'], ['m', 'M']].each do |file_type, display_status|
        res << list_files(file_or_dir, :type => file_type).map { |e| file_statuses[File.expand_path(e, dir)] ||= display_status }
      end
    end
    
    file_statuses.sort.map do |filepath, display_status|
      {:path => filepath, :display => shorten(filepath, base_dir), :status => GIT_SCM_STATUS_MAP[display_status]}
    end
  end
  
  def list_files(dir, options = {})
    options[:exclude_file] ||= File.exists?(excl_file = git_dir(dir) + '/info/exclude') ? excl_file : nil
    excl_args = options[:exclude_file] ? " --exclude-from=#{e_sh options[:exclude_file]}" : ''
    options[:type] ||= nil
    type_arg = options[:type] && "-#{options[:type]}"
     %x{#{e_sh git} ls-files #{type_arg} --exclude-per-directory=.gitignore#{excl_args}}.split("\n")
  end
  
  def run
    puts '<h2>Status for ' + paths.map { |e| "‘#{htmlize(shorten(e))}’" }.join(', ') + '</h2>'
    puts '<pre>'

    status(paths).each do |e|
      puts "<span title='#{htmlize(e[:status][:long])}'>#{htmlize(e[:status][:short])}</span> <a href='txmt://open?url=file://#{e_url e[:path]}'>#{htmlize(e[:display])}</a>"
    end

  end
  
  def parse_status(input)
    output = []
    file_statuses = {}
    state = nil
    input.split("\n").each do |line|
      case line
      when /^# Changes to be committed:/
        state = :added
      when /^# Changed but not updated:/
        state = :modified
      when /^# Untracked files:/
        state = :untracked
      when /^#\t([a-z ]+): (.*)$/
        filename = $2
        status_description = $1
        status = case $1
        when "new file"
          state == :added ? "A" : "?"
        when "deleted"
          "D"
        when "modified"
          "M"
        else
          "?"
        end
        file_statuses[filename] ||= status
      end
      
      file_statuses
    end
    
  end
end