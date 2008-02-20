class SCM::Git::Status < SCM::Git
  
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
  
  def status(file_or_dir = nil, options = {})
    file_or_dir = file_or_dir.flatten.first if file_or_dir.is_a?(Array)
    file_or_dir = file_or_dir.dup if file_or_dir
    chdir_base
    base_dir = git_base
    
    file_statuses = {}
    
    results = parse_status(command("status"))
    results.each do |file, status|
      file_statuses[expand_path_preserving_trailing_slash(file, base_dir)] = status
    end
    
    sorted_results = file_statuses.sort.map do |filepath, display_status|
      {:path => filepath, :display => shorten(filepath, base_dir), :status => GIT_SCM_STATUS_MAP[display_status]}
    end
    
    if file_or_dir
      file_or_dir << "/" if File.directory?(file_or_dir) unless /\/$/.match(file_or_dir)
      sorted_results.select do |status|
        if is_a_path?(status[:path]) && /^#{Regexp.escape(status[:path])}/i.match(file_or_dir)
          # promote this status on down and keep it if it's the parent folder of our target file_or_dir
          status[:path] = file_or_dir
          status[:display] = shorten(file_or_dir, base_dir)
          true
        else
          /^#{Regexp.escape(file_or_dir)}/i.match(status[:path])
        end
      end
    else
      sorted_results
    end
  end
  
  def is_a_path?(filepath)
    /\/$/.match(filepath)
  end
  
  def expand_path_preserving_trailing_slash(file, base_dir)
    result = File.expand_path(file, base_dir)
    result << "/" if is_a_path?(file)
    result
  end
  
  def run(file_or_path = paths.first)
    puts '<h2>Status for ' + file_or_path.map { |e| "‘#{htmlize(shorten(e))}’" }.join(', ') + '</h2>'
    puts '<pre>'
    status(file_or_path).each do |e|
      puts "<span title='#{htmlize(e[:status][:long])}'>#{htmlize(e[:status][:short])}</span> <a href='txmt://open?url=file://#{e_url e[:path]}'>#{htmlize(e[:display])}</a>"
    end
    puts "</pre>"
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
      when /^#\t(([a-z ]+): +){0,1}(.*)$/
        filename = $3
        status_description = $2
        status = case status_description
        when "new file"
          state == :added ? "A" : "?"
        when "deleted"
          "D"
        when "modified"
          "M"
        when "unmerged"
          # do a quick check to see if the merge is resolved
          file_contents = File.exist?(filename) ? File.read(filename) : ""
          if /^={7}$/.match(file_contents) && /^\<{7} /.match(file_contents) && /^>{7} /.match(file_contents)
            "C"
          else
            "G"
          end
        else
          "?"
        end
        file_statuses[filename] ||= status
      end
      
    end
    file_statuses
  end
end