class SCM::Git::Diff
  include SCM::Git::CommonCommands
    
  def diff(file, base = nil)
    base = File.expand_path("..", git_dir(file)) if base.nil?
    Dir.chdir(base)
    file = '.' if file == base
    parse_diff(command("diff", file.sub(/^#{Regexp.escape base}\//, '')))
  end
  
  def parse_diff(diff_content)
    output = []
    current = nil
    ln_left, ln_right = 0,0
    diff_content.split("\n").each do |line|
      case line
      when /^diff \-\-git/
      when /^index ([0-9a-f]+)\.\.([0-9a-f]+) ([0-9]*)/i
        current = {:left => {}, :right => {}, :lines => []}
        output << current
        current[:index_start] = $1
        current[:index_end] = $2
        current[:index_mode] = $3
      when /^\-\-\- [ab]{0,1}(.+)/
        current[:left][:filepath] = $1
      when /^\+\+\+ [ab]{0,1}(.+)/
        current[:right][:filepath] = $1
      when /@@ \-(\d+),(\d+) \+(\d+),(\d+) @@ (.*)$/  # @@ -5,6 +5,25 @@ class SCM::Git::Diff
        ln_left = $1.to_i
        ln_left_count = $2.to_i
        ln_right = $3.to_i
        ln_right_count = $4.to_i
        current[:left][:line_numbers] = ln_left..(ln_left + ln_left_count)
        current[:right][:line_numbers] = ln_right..(ln_right + ln_right_count)
        current[:first_line] = $5
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
        current[:lines] << { :text => $1}
      end
    end
    output
  end
end