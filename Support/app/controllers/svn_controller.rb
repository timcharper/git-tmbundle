class SvnController < ApplicationController
  def dcommit
    puts "<h2>Committing to Subversion Repository</h2>"
    puts htmlize(svn_dcommit)
  end
  
  def rebase
    puts "<h2>Rebasing Subversion Repository</h2>"
    puts htmlize(svn_rebase)
  end
  
  def fetch
    puts "<h2>Fetching Subversion Repository</h2>"
    puts htmlize(svn_fetch)
  end
  
end