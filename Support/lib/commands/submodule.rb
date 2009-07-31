require 'digest/md5'
require 'fileutils'

class SCM::Git::Submodule < SCM::Git::CommandProxyBase
  def init_and_update
    output = @base.command("submodule", "init")
    output << @base.command("submodule", "update")
    output
  end
  
  def all(options = {})
    list(options).map do |sm|
      SubmoduleProxy.new(@base, self, sm)
    end
  end
  
  def add(repository, path)
    path = @base.make_local_path(path)
    @base.popen_command("submodule", "add", "--", repository, path)
  end
  
  protected
    def list(options = {})
      args = ["ls-files", "--stage"]
      args << options[:path] if options[:path]
      @base.command(*args).split("\n").grep(/^160000 /).map do |line|
        next unless line.match(/^160000\s*([a-f0-9]+)\s*([0-9]+)\s*(.+)/)
        {
          :revision => $1,
          :path => $3
        }
      end.compact
    end
    
  class SubmoduleProxy
    attr_reader :revision, :path, :tag, :state
  
    def initialize(base, parent, options = {})
      @base, @parent, @tag = base, parent, tag
      options.each do |key, value|
        instance_variable_set("@#{key}", value)
      end
    end
    
    def url
      @url ||= @base.config[:local, "submodule.#{path}.url"]
    end
    
    def name
      path
    end
    
    def abs_cache_path
      @abs_cache_path ||= File.join(@base.path, ".git/submodule_cache", Digest::MD5.hexdigest("#{path} #{url}"))
    end
    
    def abs_path
      @abs_path ||= File.join(@base.path, @path)
    end
    
    def cache
      if cloned?
        if File.exist?(abs_cache_path)
          puts "<h2>Cowardly refusing to overwrite cached submodule in #{abs_cache_path} (please look at the contents of that folder, move it out of the way, then try again)<h2>" 
          abort
        end
        
        FileUtils.mkdir_p(File.dirname(abs_cache_path))
        FileUtils.mv(abs_path, abs_cache_path, :force => true)
        true
      end
    end
    
    def restore
      return false if Dir.has_a_file?(abs_path)
      if cached?
        FileUtils.rm_rf(abs_path) 
        FileUtils.mkdir_p(File.dirname(abs_path))
        FileUtils.mv(abs_cache_path, abs_path, :force => true)
      end
      true
    end
    
    def git
      @git ||= @base.with_path(abs_path)
    end
    
    def current_revision(reload = false)
      @current_revision = nil if reload
      @current_revision ||= git.current_revision
    end
    
    def current_revision_description
      @current_revision_description ||= git.describe(current_revision)
    end
    
    def revision_description
      @revision_description ||= git.describe(revision)
    end
    
    def modified?
      return false unless cloned?
      current_revision != revision
    end
    
    def cloned?
      File.exist?(File.join(abs_path, ".git")) || cached?
    end
    
    def cached?
      File.exist?(abs_cache_path)
    end
    
    def update
      @base.command("submodule", "update", path)
    end
    
    def init
      @base.command("submodule", "init", path)
    end
  end
end

class Dir
  def self.has_a_file?(abs_path)
    Dir[abs_path + "/**/*"].any? {|f| File.file?(f) }
  end
end