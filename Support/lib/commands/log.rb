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

  def run(path = paths.first)
    path = path.gsub(/#{git_base}\/{0,1}/, "")
    # Get the desired revision number
    revisions = choose_revision(path, "View revision of #{File.basename(path)}", 1)
    return if revisions.nil?

    files            = []

    TextMate.call_with_progress(:title => "View Revision",
                              :summary => "Retrieving revision data…",
                              :details => "#{File.basename(path)}") do |dialog|
      revisions.each do |revision|
        # Get the file at the desired revision
        dialog.parameters = {'summary' => "Retrieving revision #{revision}…"}

        temp_name = '/tmp/' + human_readable_mktemp(path, revision)
        File.open(temp_name, "w") {|f| f.puts command("show", "#{revision}:#{path}") }
        # 
        # svn_cmd("cat -r#{revision} #{e_sh path} > #{e_sh temp_name}")
        files << temp_name
      end
    end

    # Open the files in TextMate and delete them on close
    ### mate -w doesn't work on multiple files, so we'll do one file at a time...
    files.each do |file|
      fork do 
        %x{"#{ENV['TM_SUPPORT_PATH']}/bin/mate" -w #{e_sh(file)}}
        File.delete(file)
      end
    end
  end

  # on failure: returns nil
  def choose_revision(path, prompt = "Choose a revision", number_of_revisions = 1)
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
    TextMate::UI.dialog(:nib => ListNib,
                            :center => true,
                            :parameters => {'title' => prompt,'entries' => [], 'hideProgressIndicator' => false}) do |dialog|

      # Parse the log
      plist = []
      log_data = stringify(log(path))
      dialog.parameters = {'entries' => log_data, 'hideProgressIndicator' => true}

      dialog.wait_for_input do |params|
        # puts "<br/>" * 10
        puts params.inspect
        revision = params['returnArgument']
        button_clicked = params['returnButton']
        # STDERR.puts params['returnButton']
#        STDERR.puts "Want:#{number_of_revisions} got:#{revision.length}"

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

#      dialog.close
    end

    # Return the revision number or nil
    revision = nil if revision == 0
    revision
  end


  # def run_old
  #   git   = SCM::Git.new
  #   paths = paths(:fallback => :current_file, :unique => true)
  #   base  = nca(paths)
  # 
  #   Dir.chdir(base)
  # 
  #   paths.each do |path|
  # 
  #     puts "<h1>Log for ‘#{htmlize(shorten(path, base))}’</h1>"
  #     colors = %w[ white lightsteelblue ]
  # 
  #     file = if path == base then '.' else shorten(path, base) end
  #     output = log(file)
  #     output.scan(/^commit (.+)$\n((?:\w+: .*\n)*)((?m:.*?))(?=^commit|\z)/) do |e|
  #         commit, msg = $1, $3
  #         headers = $2.scan(/(\w+):\s+(.+)/)
  # 
  #         puts "<div style='background: #{colors[0]};'>"
  #         puts "<h2>Commit #{htmlize commit.sub(/^(.{8})(.{10}.*)/, '\1…')}</h2>"
  #         puts headers.map { |e| "<dt>#{htmlize e[0]}</dt>\n<dd>#{htmlize e[1]}</dd>\n" }
  #         puts "<p>#{htmlize msg.gsub(/\A\n+|\n+\z/, '').gsub(/^    /, '')}</p>"
  #         puts "</div>"
  # 
  #         colors = [colors[1], colors[0]]
  #     end
  #   end
  # end
  
  def log(file_or_directory)
    parse_log(command("log", file_or_directory))
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