class SCM::Git::Config < SCM::Git::CommandProxyBase
  DEFAULT_LOG_LIMIT = 100
  def [](*params)
    scope, key = process_keys(params)
    r = base.command(*(["config"] + config_args(scope) + [key]))
    r.blank? ? nil : r.gsub(/\n$/, '')
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
  
  def log_limit
    self["git-tmbundle.log.limit"] || DEFAULT_LOG_LIMIT 
  end
  
  def show_diff_check?
    %w[yes 1 auto].include?(self["git-tmbundle.show-diff-check"].to_s.downcase.strip)
  end
  
  def context_lines
    self["git-tmbundle.log.context-lines"]
  end
  
  protected
    def config_args(scope)
      case scope.to_s
      when "global"
        ["--global"]
      when "local", "file"
        ["--file", File.join(@base.path, ".git/config")]
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