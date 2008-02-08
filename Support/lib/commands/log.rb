require "#{ENV["TM_SUPPORT_PATH"]}/lib/osx/plist"
require "#{ENV["TM_SUPPORT_PATH"]}/lib/ui"
require "#{ENV["TM_SUPPORT_PATH"]}/lib/progress"
require "#{ENV["TM_SUPPORT_PATH"]}/lib/escape"
require 'date.rb'
require 'time.rb'

location = ENV["TM_BUNDLE_SUPPORT"]
$nib = "#{location}/nibs/RevisionSelector.nib"
$tm_dialog = "#{ENV["TM_SUPPORT_PATH"]}/bin/tm_dialog"
ListNib = File.dirname(__FILE__) + "/../../nibs/RevisionSelector.nib"


class SCM::Git::Log
  include SCM::Git::CommonCommands
  
  def initialize
    Dir.chdir(git_base)
  end
  
  
  def human_readable_mktemp(filename, rev)
    extname = File.extname(filename)
    filename = File.basename(filename)
    # TODO: Make sure the filename can fit in 255 characters, the limit on HFS+ volumes.

    "#{filename.sub(extname, '')}-r#{rev}#{extname}"
  end
  
  def show(fullpath, revision)
    path = make_local_path(fullpath)
    path = "" if path=="."
    command("show", "#{revision}:#{path}")
  end

  def run(fullpath = paths.first)
    path = make_local_path(fullpath)
    # Get the desired revision number
    if File.directory?(fullpath)
      title = "View revision of Directory #{path}"
    else
      title = "View revision of file #{File.basename(path)}"
    end
    revisions = choose_revision(path, title, :multiple)
    return if revisions.nil?

    files            = []

    TextMate.call_with_progress(:title => "View Revision",
                              :summary => "Retrieving revision data…",
                              :details => "#{File.basename(path)}") do |dialog|
      revisions.each do |revision|
        # Get the file at the desired revision
        dialog.parameters = {'summary' => "Retrieving revision #{revision}…"}

        temp_name = '/tmp/' + human_readable_mktemp(path, revision)
        File.open(temp_name, "w") {|f| f.puts show(path, revision) }
        files << temp_name
      end
    end

    # Open the files in TextMate and delete them on close
    ### mate -w doesn't work on multiple files, so we'll do one file at a time...
    files.each do |file|
      fork do 
        tm_open(file, :wait => true)
        File.delete(file)
      end
    end
  end

  # on failure: returns nil
  def choose_revision(path, prompt = "Choose a revision", number_of_revisions = 1, options = {})
    path = make_local_path(path)
    # Validate file
    # puts command("status", path)
    if /error: pathspec .+ did not match any file.+ known to git./.match(command("status", path))
      TextMate::UI.alert(:warning, "File “#{File.basename(path)}” is not in the repository.", "Please add the file to the repository before using this command.")
      return nil
    end

    # # Get the server name   
    # info = YAML::load(svn_cmd("info #{escaped_path}"))
    # repository = info['Repository Root']
    # uri = URI::parse(repository)

    # the above will fail for users that run a localized system
    # instead we should do ‘svn info --xml’, though since the
    # code is not used, I just commented it. --Allan 2007-02-20

    # Display progress dialog
    # Show the log
    revision = 0
    log_data = nil
    
    TextMate::UI.dialog(:nib => ListNib,
                            :center => true,
                            :parameters => {'title' => prompt,'entries' => [], 'hideProgressIndicator' => false}) do |dialog|

      # Parse the log
      log_data = stringify(log(path, :limit => 200))
      dialog.parameters = {'entries' => log_data, 'hideProgressIndicator' => true}

      dialog.wait_for_input do |params|
        revision = params['returnArgument']
        button_clicked = params['returnButton']

        if (button_clicked != nil) and (button_clicked == 'Cancel')
          false # exit
        else
          unless (number_of_revisions == :multiple) or (revision.length == number_of_revisions) then
            TextMate::UI.alert(:warning, "Please select #{number_of_revisions} revision#{number_of_revisions == 1 ? '' : 's'}.", "So far, you have selected #{revision.length} revision#{revision.length == 1 ? '' : 's'}.")
            true # continue
          else
            false # exit
          end
        end
      end
    end

    # Return the revision number or nil
    revision = nil if revision == 0
    if options[:sort] && revision
      time_revision_pairs = []
      selected_entries = log_data.select{ |l| revision.include?(l["rev"]) }
      selected_entries.sort!{ |a,b| a["date"] <=> b["date"] } # sorts them descending (latest on the bottom)
      selected_entries.reverse! if options[:sort] == :asc
      revision = selected_entries.map{|se| se["rev"]}
    end
    revision
  end
  
  def log(file_or_directory, options = {})
    file_or_directory = make_local_path(file_or_directory)
    params = ["log"]
    params += ["-n", options[:limit]] if options[:limit]
    params << file_or_directory
    parse_log(command(*params))
  end
  
  def parse_log(log_content)
    output = []
    current = nil
    log_content.split("\n").each do |line|
      case line
      when /^commit *(.+)/
        output << (current = {})
        current[:rev] = $1
      when /Author: *(.+)/
        current[:author] = $1
      when /Date: *(.+)/
        current[:date] = Time.parse($1)
      when / {4}(.*)/
        current[:msg]||=""
        current[:msg] << $1
        current[:msg] << "\n"
      end
    end
    output
  end
  
  def stringify(results)
    results.each{|r| r.stringify_keys! }
  end
end

class Hash
  def stringify_keys!
    keys.each{|k|
      if k.is_a?(Symbol)
        value = delete(k)
        self[k.to_s] = value
      end
    }
  end
end