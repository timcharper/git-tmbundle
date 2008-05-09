require LIB_ROOT + "/parsers.rb"
require LIB_ROOT + "/commands/proxy_command_base.rb"
require LIB_ROOT + "/commands/config.rb" # we have to specifically require this
module SCM
  class Git
    GIT_SCM_STATUS_MAP = {
      'A' => {:short => 'A', :long => 'added',        :foreground => '#008000', :background => '#bbffb3'},
      '+' => {:short => '+', :long => 'added',        :foreground => '#008000', :background => '#bbffb3'},
      'D' => {:short => 'D', :long => 'deleted',      :foreground => '#FF0000', :background => '#f59696'},
      'G' => {:short => 'G', :long => 'merged',       :foreground => '#eb6400', :background => '#f7e1ad'},
      'U' => {:short => 'U', :long => 'updated',      :foreground => '#eb6400', :background => '#f7e1ad'},
      'M' => {:short => 'M', :long => 'modified',     :foreground => '#eb6400', :background => '#f7e1ad'},
      'L' => {:short => 'L', :long => 'locked',       :foreground => nil      , :background => nil      },
      'B' => {:short => 'B', :long => 'broken',       :foreground => nil      , :background => nil      },
      'R' => {:short => 'R', :long => 'renamed',      :foreground => '#FF0000', :background => '#f59696'},
      'C' => {:short => 'C', :long => 'conflict',     :foreground => '#008080', :background => '#A3CED0'},
      '!' => {:short => '!', :long => 'missing',      :foreground => '#008080', :background => '#A3CED0'},
      '"' => {:short => '"', :long => 'typeconflict', :foreground => '#008080', :background => '#A3CED0'},
      '?' => {:short => '?', :long => 'unknown',      :foreground => '#800080', :background => '#edaef5'},
      'I' => {:short => 'I', :long => 'ignored',      :foreground => '#800080', :background => '#edaef5'},
      'X' => {:short => 'X', :long => 'external',     :foreground => '#800080', :background => '#edaef5'},
    }
    
    DEFAULT_DIFF_LIMIT = 3000
    
    def short_rev(rev)
      rev.to_s[0..7]
    end
    
    def initialize
      chdir_base
    end
    
    def version
      @version ||= command("version").scan(/[0-9\.]+/).first
    end
    
    def version_1_5_3?
      /^1\.5\.3\./.match(version)
    end
    
    def version_1_5_4?
      /^1\.5\.4\./.match(version)
    end
    
    def command_str(*args)
      %{#{e_sh git} #{args.map{ |arg| e_sh(arg) } * ' '}}
    end

    def command(*args)
      %x{#{command_str(*args)} 2>&1 }
    end
    
    def popen_command(*args)
      cmd = command_str(*args)
      IO.popen("#{cmd} 2>&1", "r")
    end
    
    def git
      git ||= e_sh(ENV['TM_GIT'] || 'git')
    end
    
    def chdir_base
      Dir.chdir(git_base)
    end
  
    def git_base
      File.expand_path('..', git_dir(paths.first))
    end

    def dir_part(file_or_dir)
      File.directory?(file_or_dir) ? file_or_dir : File.split(file_or_dir).first
    end
    
    def make_local_path(fullpath)
      fullpath = fullpath.gsub(/#{git_base}\/{0,1}/, "")
      fullpath = "." if fullpath == ""
      fullpath
    end
    
    def paths(options = { :unique => true, :fallback => :project })
      if ENV.has_key? 'TM_SELECTED_FILES'
        res = Shellwords.shellwords(ENV['TM_SELECTED_FILES'])
        if(options[:unique])
          ancestors = Set.new(res)
          res = res.reject do |path|
            !path.split('/')[0...-1].inject('') do |base, dir|
              ancestors.include?(base + dir) ? false : base + dir + '/' if base
            end
          end
        end
        res
      elsif options[:fallback] == :project && ENV.has_key?('TM_PROJECT_DIRECTORY')
        ENV['TM_PROJECT_DIRECTORY'].to_a
      elsif options[:fallback] == :current_file && ENV.has_key?('TM_FILEPATH')
        ENV['TM_FILEPATH'].to_a
      elsif ENV.has_key?('TM_DIRECTORY')
        ENV['TM_DIRECTORY'].to_a
      elsif ENV.has_key?('TM_PROJECT_DIRECTORY')
        ENV['TM_PROJECT_DIRECTORY'].to_a
      else
        raise "No selected files." # FIXME throw an object with more info
      end
    end

    def git_dir(file_or_dir)
      file = %x{
        cd #{e_sh dir_part(file_or_dir)}
        #{git} rev-parse --git-dir;
        cd - > /dev/null;
      }.chomp
      File.expand_path(file, dir_part(file_or_dir))
    end

    def nca(files = nil)
      files||=paths
      if(files.size == 1)
        File.directory?(files.first) ? files.first : File.split(files.first).first
      else
        components = files.map { |e| e.split('/') }
        i = 0
        while components.all? { |e| e.size > i && e[i] == components[0][i] }
          i += 1
        end
        i == 0 ? '/' : components[0][0...i].join('/')
      end
    end
    
    def remotes
      remote.remote_names
    end
    
    def list_files(dir, options = {})
      options[:exclude_file] ||= File.exists?(excl_file = git_dir(dir) + '/info/exclude') ? excl_file : nil
      options[:type] ||= nil
      params = []
      params << "-#{options[:type]}" if options[:type]
      params << "--exclude-per-directory=.gitignore"
      params << "--exclude-from=#{e_sh options[:exclude_file]}" if options[:exclude_file]
      
      command("ls-files", *params).split("\n")
    end
    
    def create_tag(name)
      chdir_base
      %x{#{command_str("tag", name)}}
      true
    end
  
    def revert(paths = [])
      output = ""
      
      chdir_base
        
      paths.each do |e|
        output << command("checkout", "--", shorten(e, git_base))
      end
      output
    end
  
    def self.const_missing(name)
      @last_try||=nil
      raise if @last_try==name
      @last_try = name
    
      file = File.dirname(__FILE__) + "/commands/#{name.to_s.downcase}.rb"
      require file
      klass = const_get(name)
    rescue LoadError
      raise "Class not found: #{name}"
    end
    
    def merge_message
      return unless File.exist?(File.join(git_base, ".git/MERGE_HEAD"))
      File.read(File.join(git_base, ".git/MERGE_MSG"))
    end
    
    def initial_commit_pending?
      /^# Initial commit$/.match(command("status")) ? true : false
    end
    
    def status(file_or_dir = nil, options = {})
      file_or_dir = file_or_dir.flatten.first if file_or_dir.is_a?(Array)
      file_or_dir = file_or_dir.dup if file_or_dir
      chdir_base
      
      results = parse_status(command("status"))
      
      if file_or_dir
        file_or_dir << "/" if File.directory?(file_or_dir) unless /\/$/.match(file_or_dir)
        results.select do |status|
          if is_a_path?(status[:path]) && /^#{Regexp.escape(status[:path])}/i.match(file_or_dir)
            # promote this status on down and keep it if it's the parent folder of our target file_or_dir
            status[:path] = file_or_dir
            status[:display] = shorten(file_or_dir, git_base)
            true
          else
            /^#{Regexp.escape(file_or_dir)}/i.match(status[:path])
          end
        end
      else
        results
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
    
    def clean_directory?
      status.empty?
    end

    def commit(msg, files = ["."], options = {})
      args = ["commit"]
      args << "--amend" if options[:amend]
      args += ["-m", msg, *files]
      parse_commit(command(*args))
    end
    
    def add(files = ["."])
      command("add", *files)
    end

    def rm(files = ["."])
      command("rm", *files)
    end
    
    def auto_add_rm(files)
      chdir_base
      add_files = files.select{ |f| File.exists?(f) }
      remove_files = files.reject{ |f| File.exists?(f) }
      res = ""
      res << add(add_files) unless add_files.empty?
      res << rm(remove_files) unless remove_files.empty?
      res
    end
    
    def merge(merge_from_branch)
      parse_merge(command("merge", merge_from_branch))
    end
    
    def show(fullpath, revision)
      path = make_local_path(fullpath)
      path = "" if path=="."
      command("show", "#{revision}:#{path}")
    end
    
    def push(remote, options = {})
      options = options.dup
      args = ["push", remote]
      args << options.delete(:branch) if options[:branch]
      args << options.delete(:tag) if options[:tag]
      
      p = popen_command(*args)
      process_push(p, options)
    end
    
    def pull(remote, remote_merge_branch = nil, callbacks = {})
      args = ["pull", remote]
      args << remote_merge_branch.split('/').last if remote_merge_branch
      p = popen_command(*args)
      process_pull(p, callbacks)
    end
    
    def fetch(remote, callbacks = {})
      p = popen_command("fetch", remote)
      process_fetch(p, callbacks)
    end

    def show_to_tmp_file(fullpath, revision)
      temp_name = '/tmp/' + human_readable_mktemp(fullpath, revision)
      File.open(temp_name, "w") {|f| f.puts show(fullpath, revision) }
      temp_name
    end

    def human_readable_mktemp(filename, rev)
      extname = File.extname(filename)
      filename = File.basename(filename)
      # TODO: Make sure the filename can fit in 255 characters, the limit on HFS+ volumes.
      "#{filename.sub(extname, '')}-rev-#{rev}#{extname}"
    end
    
    %w[config branch stash svn remote submodule].each do |command|
      class_eval <<-EOF
      def #{command}
        @#{command} ||= SCM::Git::#{command.classify}.new(self)
      end
      EOF
    end
    
    def annotate(filepath, revision = nil)
      file = make_local_path(filepath)
      args = [file]
      args << revision unless revision.nil? || revision.empty?
      chdir_base
      output = command("annotate", *args)
      if output.match(/^fatal:/)
        puts output 
        return nil
      end
      parse_annotation(output)
    end

    def diff(options = {})
      options = {:file => options} unless options.is_a?(Hash)
      params = ["diff"]
      params << ["-U", options[:context_lines]] if options[:context_lines]
      
      lr = get_range_arg(options)
      params << lr if lr
      params << make_local_path(options[:path]) if options[:path]
      
      output = command(*params)
      File.open("/tmp/output.diff", "w") {|f| f.puts output }
      parse_diff(output)
    end
    
    def log(options = {})
      params = ["log"]
      params += ["-n", options[:limit]] if options[:limit]
      params << "-p" if options[:with_log]
      params << options[:branch]  if options[:branch]
      
      lr = get_range_arg(options)
      params << lr if lr
      
      params << make_local_path(options[:path]) if options[:path]
      parse_log(command(*params))
    end
    
    def init(directory)
      Dir.chdir(directory) do
        command("init")
      end
    end
    
    def logger
      @logger ||= 
        begin
          require 'logger'
          Logger.new(ROOT + "/git.log")
        end
    end
    
    protected
      def get_range_arg(options, keys = [:revisions, :branches, :tags])
        return options[:since] if options[:since]
        lr = [:revisions, :revision, :branches, :tags].map{ |k| options[k] }.compact.first
        case lr
        when Array, Range
          "#{lr.first}..#{lr.last}"
        when String
          lr.include?("..") ? lr : "#{lr}^..#{lr}"
        else
          lr
        end
      end
    
    include Parsers
  end
end

Git = SCM::Git