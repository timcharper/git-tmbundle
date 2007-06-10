require ENV['TM_SUPPORT_PATH'] + '/lib/escape.rb'
require 'shellwords'
require 'set'

module SCM
  class Status
    attr_reader :short, :long, :foreground, :background

    def initialize(short, long, foreground = nil, background = nil)
      @short      = short
      @long       = long
      @foreground = foreground
      @background = background
    end

    @@Map = {
      'A' => Status.new('A', 'added',        '#008000', '#bbffb3'),
      '+' => Status.new('+', 'added',        '#008000', '#bbffb3'),
      'D' => Status.new('D', 'deleted',      '#FF0000', '#f59696'),
      'G' => Status.new('G', 'merged',       '#eb6400', '#f7e1ad'),
      'U' => Status.new('U', 'updated',      '#eb6400', '#f7e1ad'),
      'M' => Status.new('M', 'modified',     '#eb6400', '#f7e1ad'),
      'L' => Status.new('L', 'locked'                            ),
      'B' => Status.new('B', 'broken'                            ),
      'R' => Status.new('R', 'replaced',     '#FF0000', '#f59696'),
      'C' => Status.new('C', 'conflict',     '#008080', '#A3CED0'),
      '!' => Status.new('!', 'missing',      '#008080', '#A3CED0'),
      '"' => Status.new('"', 'typeconflict', '#008080', '#A3CED0'),
      '?' => Status.new('?', 'unknown',      '#800080', '#edaef5'),
      'I' => Status.new('I', 'ignored',      '#800080', '#edaef5'),
      'X' => Status.new('X', 'external',     '#800080', '#edaef5'),
    }

    def Status.get(short)
      @@Map[short]
    end
  end

  class Git
    def initialize
      @git = e_sh(ENV['TM_GIT'] || 'git')
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
      elsif options[:fallback] == :current_file && ENV.has_key?('TM_PROJECT_DIRECTORY')
        ENV['TM_FILEPATH'].to_a
      else
        raise "No selected files." # FIXME throw an object with more info
      end
    end

    def shorten(path, base = nil)
      if base && path =~ /^#{Regexp.escape base}\/(.+)$/
        $1
      elsif path == ENV['TM_PROJECT_DIRECTORY']
        File.basename(path)
      elsif path =~ /^#{Regexp.escape ENV['TM_PROJECT_DIRECTORY']}\/(.+)$/
        $1
      elsif path =~ /^#{Regexp.escape ENV['HOME']}\/(.+)$/
        '~/' + $1
      else
        $1
      end
    end

    def dir_part(file_or_dir)
      File.directory?(file_or_dir) ? file_or_dir : File.split(file_or_dir).first
    end

    def git_dir(file_or_dir)
      file = %x{
        cd #{e_sh dir_part(file_or_dir)}
        #{@git} rev-parse --git-dir;
        cd -;
      }.chomp
      File.expand_path(file, dir_part(file_or_dir))
    end

    def nca(files)
      if(files.size == 1)
        files.first
      else
        components = files.map { |e| e.split('/') }
        i = 0
        while components.all? { |e| e.size > i && e[i] == components[0][i] }
          i += 1
        end
        i == 0 ? '/' : components[0][0...i].join('/')
      end
    end

    def status(files = nil, options = {})
      files = paths if files.nil?
      base_dir = nca(files)

      files.map do |file_or_dir|
        excl_file = git_dir(file_or_dir) + '/info/exclude'
        excl_args = if File.exists?(excl_file) then " --exclude-from=#{e_sh excl_file}"; else ''; end

        dir = dir_part(file_or_dir)
        Dir.chdir(dir)

        res = []
        res << %x{#{e_sh @git} ls-files -o --exclude-per-directory=.gitignore#{excl_args}}.split("\n").map { |e| { :path => File.expand_path(e, dir), :display => shorten(File.expand_path(e, dir), base_dir), :status => Status.get('?') } }
        res << %x{#{e_sh @git} ls-files -m --exclude-per-directory=.gitignore#{excl_args}}.split("\n").map { |e| { :path => File.expand_path(e, dir), :display => shorten(File.expand_path(e, dir), base_dir), :status => Status.get('M') } }
      end.flatten
    end
  end
end

if __FILE__ == $0

  git = SCM::Git.new

  status = git.status(["/Users/duff/Source/Avian_git"])
  status.each { |e| puts "#{e[:status].short} #{e[:display]}" }

end
