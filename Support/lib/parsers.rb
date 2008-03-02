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
end