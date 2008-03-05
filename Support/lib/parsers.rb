module Parsers
  def parse_status(input)
    base_dir = git_base
    file_statuses = {}

    parse_status_hash(input).each do |file, status|
      file_statuses[expand_path_preserving_trailing_slash(file, base_dir)] = status
    end

    sorted_results = file_statuses.sort.map do |filepath, display_status|
      {:path => filepath, :display => shorten(filepath, base_dir), :status => Git::GIT_SCM_STATUS_MAP[display_status]}
    end
  end
  
  def parse_status_hash(input)
    output = []
    file_statuses = {}
    state = nil
    input.split("\n").each do |line|
      case line
      when /^# Changes to be committed:/
        state = :added
      when /^# Changed but not updated:/
        state = :modified
      when /^# Untracked files:/
        state = :untracked
      when /^#\t(([a-z ]+): +){0,1}(.*)$/
        filename = $3
        status_description = $2
        status = case status_description
        when "new file"
          state == :added ? "A" : "?"
        when "renamed"
          filename = filename.split(/ +\-> +/).last
          "R"
        when "deleted"
          "D"
        when "modified"
          "M"
        when "unmerged"
          # do a quick check to see if the merge is resolved
          file_contents = File.exist?(filename) ? File.read(filename) : ""
          if /^={7}$/.match(file_contents) && /^\<{7} /.match(file_contents) && /^>{7} /.match(file_contents)
            "C"
          else
            "G"
          end
        else
          "?"
        end
        file_statuses[filename] ||= status
      end

    end
    file_statuses
  end
  
  def parse_commit(commit_output)
    result = {:output => ""}
    commit_output.split("\n").each do |line|
      case line
      when /^ *Created commit ([a-f0-9]+): (.*)$/
        result[:rev] = $1
        result[:message] = $2
      when /^ *([0-9]+) files changed, ([0-9]+) insertions\(\+\), ([0-9]+) deletions\(\-\) *$/
        result[:files_changed] = $1.to_i
        result[:insertions] = $2.to_i
        result[:deletions] = $3.to_i
      else
        result[:output] << "#{line}\n"
      end
    end
    result
  end
  
  def parse_annotation(input)
    require 'time.rb'
    require 'date.rb'
    
    output = []
    match_item = /([^\t]+)\t/
    match_last_item = /([^\)]+)\)/
    input.split("\n").each do |line|
      if /#{match_item}\(#{match_item}#{match_item}#{match_last_item}(.*)$/i.match(line)
        rev,author,date,ln,text = $1,$2,$3,$4,$5
        nc = /^0+$/.match(rev)
        output << {
          :rev => nc ? "-current-" : rev,
          :author => nc ? "-none-" : author.strip,
          :date => nc ? "-pending-" : Time.parse(date),
          :ln => ln.to_i,
          :text => text
        }
      else
        raise "didnt recognize line #{line}"
      end
    end
    output
  end
  
  def parse_merge(input)
    output = {:text => "", :conflicts => []}
    input.split("\n").each do |line|
      case line
      when /^CONFLICT \(.+\): Merge conflict in (.+)$/
        output[:conflicts] << $1
      else
        output[:text] << "#{line}\n"
      end
    end
    output
  end
  
  def parse_diff(diff_content)
    output = []
    current = nil
    ln_left, ln_right = 0,0
    # puts "<pre>#{htmlize(diff_content)}</pre>"
    diff_content.split("\n").each do |line|
      case line
      when /^diff \-\-git/
      when /^index (([a-f0-9]+)..([a-f0-9]+)){0,1}/i
        current = {:left => {}, :right => {}, :lines => []}
        current[:left][:index] = $2
        current[:right][:index] = $3
        
        output << current
        /([0-9a-f]+)\.\.([0-9a-f]+) ([0-9]+)/i.match($1)
        current[:index_start] = $1
        current[:index_end] = $2
        current[:index_mode] = $3
      when /^\-\-\- ([ab]\/){0,1}(.+?)(\t*)$/
        current[:left][:filepath] = $2 unless $2 == "/dev/null"
      when /^\+\+\+ ([ab]\/){0,1}(.+?)(\t*)$/
        current[:right][:filepath] = $2 unless $2 == "/dev/null"
      when /^@@ \-(\d+)(,(\d+)){0,1} \+(\d+)(,(\d+)){0,1} @@ {0,1}(.*)$/  # @@ -5,6 +5,25 @@ class SCM::Git::Diff
        ln_left = $1.to_i
        ln_left_count = $3.to_i
        ln_right = $4.to_i
        ln_right_count = $6.to_i
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