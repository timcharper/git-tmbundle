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
          :name => $3,
          :tag => ($5 == "undefined" ? nil : $5)
        }
      end.compact
    end
    
  class SubmoduleProxy
    attr_reader :revision, :name, :tag, :state
  
    def initialize(base, parent, options = {})
      options.each do |key, value|
        instance_variable_set("@#{key}", value)
      end
    end
  
  end
end

