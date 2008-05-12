class SCM::Git::Remote < SCM::Git::CommandProxyBase
  def [](name)
    SCM::Git::Remote::RemoteProxy.new(@base, self, name)
  end
  
  def all
    names.map do |name|
      RemoteProxy.new(self, @base, name)
    end
  end
  
  def names
    @base.command("remote").split("\n")
  end
  
  class RemoteProxy
    attr_reader :name
  
    def initialize(base, parent, name, options = {})
      @base = base
      @parent = parent
      @name = name
    end
    
    def fetch_refspec(reload = false)
      @fetch_refspec = nil if reload
      @fetch_refspec ||= @base.config["remote.#{name}.fetch"]
    end
  end
end
