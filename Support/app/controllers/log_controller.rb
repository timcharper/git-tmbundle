# encoding: utf-8
require ENV['TM_SUPPORT_PATH'] + '/lib/ui.rb'
require "#{ENV["TM_SUPPORT_PATH"]}/lib/osx/plist"
require "#{ENV["TM_SUPPORT_PATH"]}/lib/progress"
require LIB_ROOT + '/date_helpers.rb'
location = ENV["TM_BUNDLE_SUPPORT"]
$nib = "#{location}/nibs/RevisionSelector.nib"
ListNib = File.dirname(__FILE__) + "/../../nibs/RevisionSelector.nib"


class LogController < ApplicationController
  layout "application", :only => ["index", "outgoing"]
  
  include DateHelpers
  include SubmoduleHelper
  
  def index
    params[:path] ||= git.make_local_path(git.paths.first)
    path = params[:path]
    # Get the desired revision number
    if File.directory?(git.path + path)
      title = "View revision of Directory #{path}"
    else
      title = "View revision of file #{File.basename(path)}"
    end
    
    log
  end
  
  def log
    params[:limit] ||= git.config.log_limit
    log_params = params.reject(:controller, :action, :layout)
    @path = params[:path]
    @log_entries = git.with_path(params[:git_path]).log(log_params)
    @branch ||= Git.new.branch.current
    @branch_name = @branch && @branch.name
    render "log_entries", :locals => {:git => git.with_path(params[:git_path])}
  end
  
  def outgoing
    render_outgoing_for_branches(git, git.branch.all)
    git.submodule.all.each do |submodule|
      next unless submodule.git.branch.all.any? { |b| [:ahead, :diverged].include?(b.tracking_status) }
      render_outgoing_for_branches(submodule.git, submodule.git.branch.all)
    end
  end
  
  def open_revision
    file_path = params[:file_path]
    revision = params[:revision]
    line = params[:line]
    if revision.blank?
      tm_open(git.with_path(params[:git_path]).path_for(file_path), :line => line)
      abort
    end
    tmp_file = git.with_path(params[:git_path]).show_to_tmp_file(file_path, revision)
    fork do
      tm_open(tmp_file, :line => line, :wait => true)
      File.delete(tmp_file)
    end
  end
  
  def create_branch_from_revision
    revision = params[:revision]
    if revision.blank?
      TextMate::UI.alert(:warning, "Error", "Cannot create a branch from 'current'", 'OK') 
      abort
    end

    Dir.chdir(ENV['TM_PROJECT_DIRECTORY'])

    branch_name = TextMate::UI.request_string(:title => "Create Branch from revision #{revision}", :prompt => "What would you like to call this branch?")
    abort if branch_name.blank?

    output = git.branch.create(branch_name, :revision => revision)

    if output.blank? # git returns nothing if successful
      TextMate::UI.alert(:informational, "Success!", "Branch has successfully been created!", 'OK') 
    else
      TextMate::UI.alert(:warning, "Error!", "#{output}", 'OK') 
    end  
  end
  
  def create_tag_from_revision
    revision = params[:revision]
    if revision.blank?
      TextMate::UI.alert(:warning, "Error", "Cannot create a tag from 'current'", 'OK') 
      abort
    end

    tag_name = TextMate::UI.request_string(:title => "Create tag from revision #{revision}", :prompt => "What would you like to call this tag?")
    abort if tag_name.blank?

    output = git.command("tag", tag_name, revision)

    if output.blank? # git returns nothing if successful
      TextMate::UI.alert(:informational, "Success!", "Tag '#{tag_name}' has successfully been created!", 'OK') 
    else
      TextMate::UI.alert(:warning, "Error!", "#{output}", 'OK') 
    end  
  end
  
  def choose_revision(path, prompt = "Choose a revision", number_of_revisions = 1, options = {})
    path = git.make_local_path(path)
    # Validate file
    # puts command("status", path)
    if /error: pathspec .+ did not match any file.+ known to git./.match(git.command("status", path))
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
      log_data = git.log(:path => path, :limit => 200).each { |log_entry| log_entry.stringify_keys! }
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
  
  protected
    def render_outgoing_for_branches(git, branches)
      puts "<h1>Outgoing</h1>"
      branches.each do |branch|
        next unless [:ahead, :diverged].include?(branch.tracking_status)
        puts "<h2>'#{branch.name}' branch - <small> #{branch.tracking_status}</small></h2>"
        render_component(:action => "log", :git_path => git.path, :branches => "#{branch.tracking_branch_name(:long)}..#{branch.name(:long)}")
      end
    end
end