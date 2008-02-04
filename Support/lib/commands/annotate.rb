require 'time.rb'
require 'date.rb'
class SCM::Git::Annotate
  include SCM::Git::CommonCommands
  def annotate(filepath)
    file = make_local_path(filepath)
    Dir.chdir(git_base)
    output = command("annotate", file)
    if output.match(/^fatal:/)
      puts output 
      return nil
    end
    parse_annotation(output)
  end
  
  def parse_annotation(input)
    output = []
    match_item = /([^\t]+)\t/
    match_last_item = /([^\)]+)\)/
    input.split("\n").each do |line|
      if /#{match_item}\(#{match_item}#{match_item}#{match_last_item}(.*)$/i.match(line)
        rev,author,date,ln,text = $1,$2,$3,$4,$5
        output << {
          :rev => /^0+$/.match(rev) ? "-" : rev,
          :author => /Not Committed Yet/.match(author) ? "-" : author.strip,
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