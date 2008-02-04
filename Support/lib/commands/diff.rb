class SCM::Git::Diff
  include SCM::Git::CommonCommands
  
  def diff_branches(branch_left, branch_right)
    Dir.chdir(git_base)
    parse_diff(command("diff", branch_left, branch_right))
  end
  
  def diff_file(fullpath)
    path = fullpath.gsub(/#{git_base}\/{0,1}/, "")
    Dir.chdir(git_base)
    path = '.' if path == ""
    parse_diff(command("diff", path))
  end
  
  def parse_diff(diff_content)
    output = []
    current = nil
    ln_left, ln_right = 0,0
    # puts "<pre>#{htmlize(diff_content)}</pre>"
    diff_content.split("\n").each do |line|
      case line
      when /^diff \-\-git/
      when /^index(.*)$/i
        current = {:left => {}, :right => {}, :lines => []}
        output << current
        /([0-9a-f]+)\.\.([0-9a-f]+) ([0-9]+)/i.match($1)
        current[:index_start] = $1
        current[:index_end] = $2
        current[:index_mode] = $3
      when /^\-\-\- [ab]{0,1}(.+?)(\t*)$/
        current[:left][:filepath] = $1
      when /^\+\+\+ [ab]{0,1}(.+?)(\t*)$/
        current[:right][:filepath] = $1
      when /@@ \-(\d+),(\d+) \+(\d+),(\d+) @@ {0,1}(.*)$/  # @@ -5,6 +5,25 @@ class SCM::Git::Diff
        ln_left = $1.to_i
        ln_left_count = $2.to_i
        ln_right = $3.to_i
        ln_right_count = $4.to_i
        current[:left][:ln_start] ||= ln_left
        current[:right][:ln_start] ||= ln_right
        current[:left][:ln_end] = ln_left + ln_left_count
        current[:right][:ln_end] = ln_right + ln_right_count
        current[:first_line] = $5
        current[:lines] << {:type => :cut, :ln_left => "…", :ln_right => "…", :text => "" } unless current[:lines].empty?
      when /^\+(.*)$/ # insertion
        current[:lines] << {:type => :insertion, :ln_left => nil, :ln_right => ln_right, :text => $1 }
        ln_right += 1
      when /^\-(.*)$/ # deletion
        current[:lines] << {:type => :deletion, :ln_left => ln_left, :ln_right => nil, :text => $1 }
        ln_left += 1
      when /^ (.*)$/
        current[:lines] << {:ln_left => ln_left, :ln_right => ln_right, :text => $1 }
        ln_left += 1
        ln_right += 1
      when /^\\ (No newline at end of file)/
        last_line = current[:lines].last
        current[:lines] << { 
          :type => :eof,
          :ln_left => (last_line[:ln_left] && "EOF"), 
          :ln_right => (last_line[:ln_right] && "EOF"), 
          :text => $1}
      end
    end
    output
  end
end