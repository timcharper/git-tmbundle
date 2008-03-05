class SCM::Git::Diff < SCM::Git
  
  def diff_branches(branch_left, branch_right)
    Dir.chdir(git_base)
    diff(branch_left, branch_right)
  end
  
  def diff_revisions(fullpath, rev_left, rev_right)
    path = make_local_path(fullpath)
    Dir.chdir(git_base)
    diff("#{rev_left}..#{rev_right}", path)
  end
  
  def diff_file(fullpath)
    path = make_local_path(fullpath)
    Dir.chdir(git_base)
    diff(path)
  end
  
  def diff(*args)
    output = command("diff", *args)
    File.open("/tmp/output.diff", "w") {|f| f.puts output }
    parse_diff(output)
  end
end