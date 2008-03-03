module Parsers
  def parse_status(input)
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
  
end