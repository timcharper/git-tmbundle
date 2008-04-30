require 'md5'
class SCM::Git::Submodule < SCM::Git::CommandProxyBase
  def init_and_update
    output = @base.command("submodule", "init")
    output << @base.command("submodule", "update")
    output
  end
  
  def all
    list.map do |sm|
      SubmoduleProxy.new(@base, self, sm)
    end
  end
  
  def add(repository, path)
    path = @base.make_local_path(path)
    @base.popen_command("submodule", "add", "--", repository, path)
  end
  
  protected
    def list
      @base.command("submodule").split("\n").map do |line|
        next unless line.match(/^([ \-\+])*([a-f0-9]+) ([^ ]+)( \((.+)\)){0,1}/)
        {
          :state => {" " => 0, "-" => -1, "+" => 1}[$1],
          :revision => $2,
          :path => $3,
          :tag => ($5 == "undefined" ? nil : $5)
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
      @url ||= @base.command("config", "--file", File.join(@base.git_base, ".gitmodules"), "submodule.#{path}.url").strip
    end
    
    def name
      path
    end
    
    def abs_stash_path
      @abs_stash_path ||= File.join(@base.git_base, ".git/submodule_stash", MD5.hexdigest(path + "\n" + url))
    end
    
    def abs_path
      @abs_path ||= File.join(@base.git_base, @path)
    end
    
    def stash
      if File.exist?(abs_path)
        FileUtils.rm_rf(abs_stash_path)
        FileUtils.mkdir_p(File.dirname(abs_stash_path))
        FileUtils.mv(abs_path, abs_stash_path, :force => true)
        true
      end
    end
    
    def restore
      if ! File.exist?(abs_path) && File.exist?(abs_stash_path)
        FileUtils.mkdir_p(File.dirname(abs_path))
        FileUtils.mv(abs_stash_path, abs_path, :force => true)
      end
    end
  end
end

