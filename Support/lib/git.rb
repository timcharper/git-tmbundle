require ENV['TM_SUPPORT_PATH'] + '/lib/escape.rb'
require 'shellwords'
require 'set'
require File.dirname(__FILE__) + '/formatters.rb'
require File.dirname(__FILE__) + '/ruby_tm_helpers.rb'

module SCM
  class Git
    module CommonCommands
      def flush; STDOUT.flush; end;
      
      def command_str(*args)
        %{#{e_sh SCM::Git.git} #{args.map{ |arg| e_sh(arg) } * ' '}}
      end
      
      def command(*args)
        %x{#{command_str(*args)} 2>&1 }
      end
      
      def sources
        command("remote").split("\n")
      end

      def branches
        Dir.chdir(git_base)
        %x{#{e_sh git} branch}.split("\n").map { |e| { :name => e[2..-1], :default => e[0..1] == '* ' } }
      end
      
      def current_branch
        branches.find { |b| b[:default] }[:name]
      end
      
      def git
        git ||= e_sh(ENV['TM_GIT'] || 'git')
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

      def rescan_project
        %x{osascript &>/dev/null \
          -e 'tell app "SystemUIServer" to activate' \
          -e 'tell app "TextMate" to activate' &
        }
      end

    end

    include CommonCommands
    extend CommonCommands

    def create_branch(name, git_file)
      base = File.expand_path("..", git_dir(git_file))
      Dir.chdir(base)
      
      %x{#{command_str("branch", name)} && #{command_str("checkout", name)}}
    end
    
    def switch_to_branch(name, git_file)
      base = File.expand_path("..", git_dir(git_file))
      Dir.chdir(base)
      command("checkout", name)
      rescan_project
    end
    
    def revert(paths = [])
      output = ""
      
      base = nca(paths)
      Dir.chdir(base)
      
      paths.each do |e|
        output << command("checkout", shorten(e, base))
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
    rescue
      raise "Class not found: #{name}"
    end
  end
end

if __FILE__ == $0

  git = SCM::Git.new

  p git.branches("/Users/duff/Source/Avian_git/Notes/Interesting F:OSS.txt")

end
