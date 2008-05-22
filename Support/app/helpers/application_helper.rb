module ApplicationHelper
  def short_rev(rev)
    rev.to_s[0..7]
  end
  
  def git
    @git ||= Git.new
  end
  
  def link_to_relative_file(git, file_path, line = nil)
    if line 
      link_to_textmate(git.root_relative_path_for(file_path), git.path_for(file_path), line)
    else
      link_to_mate(git.root_relative_path_for(file_path), git.path_for(file_path))
    end
  end
end
