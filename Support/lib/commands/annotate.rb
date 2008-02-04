class SCM::Git::Annotate
  include SCM::Git::CommonCommands
  
  def parse_annotation(input)
    output = []
    match_item = /([^\t]+)\t/
    match_last_item = /([^\)]+)\)/
    input.split("\n").each do |line|
      if /#{match_item}\(#{match_item}#{match_item}#{match_last_item}(.*)$/i.match(line)
        rev,author,date,ln,text = $1,$2,$3,$4,$5
        output << {
          :rev => rev.strip,
          :author => author.strip,
          :date => Time.parse(date),
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