class SCM::Git::Svn < SCM::Git::CommandProxyBase
  
  def dcommit
    base.command("svn","dcommit")
  end
  
  def fetch
    base.command("svn","fetch")
  end
  
  def rebase
    base.command("svn","rebase")
  end
end