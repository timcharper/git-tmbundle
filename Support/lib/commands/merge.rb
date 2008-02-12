require ENV['TM_SUPPORT_PATH'] + '/lib/ui.rb'

class SCM::Git::Merge < SCM::Git
  def initialize
    @base = git_base
    chdir_base
  end
  
  def run
    # prompt for which branch to merge from
    c_branch = current_branch
    all_branches = branches(:all).map{|b| b[:name]} - [c_branch]
    all_branches << "" # keep the dialog from auto-selecting if there's only one other branch
    merge_from_branch = TextMate::UI.request_item(:title => "Merge", :prompt => "Merge which branch into '#{c_branch}':", :items => all_branches)
    
    if merge_from_branch.blank?
      puts "Aborted"
      abort
    end
    
    puts "<h2>Merging #{merge_from_branch} into #{c_branch}</h2>"
    flush
    
    result = parse_merge(command("merge", merge_from_branch))
    # run the merge
    puts "<pre>"
    puts result[:text]
    puts "</pre>"
    
    unless result[:conflicts].empty?
      puts "<h2>Conflicts - edit each of the following, resolve, commit, then merge again:</h2>"
      result[:conflicts].each do |conflicted_file|
        full_path = File.join(@base, conflicted_file)
        tm_open(full_path)
        puts "<div><a href='txmt://open?url=file://#{e_url full_path}'>#{conflicted_file}</a></div>"
      end
    end
    rescan_project
  end
  
  def parse_merge(input)
    output = {:text => "", :conflicts => []}
    input.split("\n").each do |line|
      case line
      when /^CONFLICT \(content\): Merge conflict in (.+)$/
        output[:conflicts] << $1
      else
        output[:text] << "#{line}\n"
      end
    end
    output
  end
end
