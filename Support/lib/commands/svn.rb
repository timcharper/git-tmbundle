class SCM::Git::Svn < SCM::Git::SubmoduleBase
  
  def dcommit
    base.command("svn","dcommit")
  end
  
  def svn_fetch
    command("svn","fetch")
  end
  
  def rebase
    base.command("svn","rebase")
  end
end