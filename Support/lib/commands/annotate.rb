require 'time.rb'
require 'date.rb'
class SCM::Git::Annotate < SCM::Git
  def annotate(filepath, revision = nil)
    file = make_local_path(filepath)
    args = [file]
    args << revision unless revision.nil? || revision.empty?
    Dir.chdir(git_base)
    output = command("annotate", *args)
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