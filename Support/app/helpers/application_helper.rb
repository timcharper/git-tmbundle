module ApplicationHelper
  def short_rev(rev)
    rev.to_s[0..7]
  end
  
  def git
    @git ||= Git.new
  end
end
