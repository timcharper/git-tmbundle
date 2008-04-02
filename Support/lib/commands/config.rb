class SCM::Git::Config < SCM::Git::CommandProxyBase
  def [](key)
    r = base.command("config", key)
    r.empty? ? nil : r.gsub(/\n$/, '')
  end

  def []=(key, value)
    base.command("config", key, value)
  end
end