class SCM::Git::Remote < SCM::Git::CommandProxyBase
  def [](name)
    @remotes ||= {}
    @remotes[name] ||= SCM::Git::Remote::RemoteProxy.new(@base, self, name)
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
    
    def remote_branch_name_for(branch_name, format = :short)
      branch_name = "refs/heads/#{branch_name}" unless branch_name[0..10] == "refs/heads/"
      sub_from, sub_to = fetch_refspec.scan(/\+?(.+)\*:(.+)\*$/).flatten
      branch_name = branch_name.gsub(sub_from, sub_to)
      if format == :short
        branch_name.gsub("refs/remotes/", "") 
      else
        branch_name
      end
    end
    
    def remote_branch_prefix
      /\*:(.+)\*/.match(fetch_refspec)
       $1
    end
  end
end
