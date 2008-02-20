class Formatters::Commit < Formatters
  def commit_merge_dialog(message)
    @message = message
    render("commit_merge_dialog")
  end
  
  def output_commit_result(res)
    puts "<pre>#{htmlize(res[:output])}</pre>"
    
    if res[:rev]
      puts "<h2>Diff of committed changes:</h2>"
      diff_formatter = Formatters::Diff.new
      diff = SCM::Git::Diff.new
      diff_result = diff.diff_revisions(".", "#{res[:rev]}^", "#{res[:rev]}")
      
      diff_formatter.content diff_result
    end
  end
end