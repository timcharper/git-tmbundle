class SCM::Git::Config < SCM::Git::CommandProxyBase
  def [](*params)
    scope, key = process_keys(params)
    r = base.command(*(["config"] + config_args(scope) + [key]))
    r.empty? ? nil : r.gsub(/\n$/, '')
  end

  def []=(*params)
    value = params.pop
    scope, key = process_keys(params)
    args = ["config"] + config_args(scope)
    if value
      args += [key, value]
    else
      args += ["--unset", key]
    end
    base.command(*args)
  end
  
  protected
    def config_args(scope)
      case scope.to_s
      when "global"
        ["--global"]
      when "local", "file"
        ["--file", File.join(@base.git_base, ".git/config")]
      when "default"
        []
      else
        raise "I don't understand the scope #{scope.inspect}"
      end
    end
    
    def process_keys(params)
      params = [:default, params.first] if params.length == 1
      params
    end
end