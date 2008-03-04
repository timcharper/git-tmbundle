require ENV['TM_SUPPORT_PATH'] + '/lib/ui.rb'

class LogController < ApplicationController
  layout nil
  
  def open_revision
    filepath = params[:filepath]
    revision = params[:revision]
    line = params[:line]
    if revision.blank?
      tm_open(filepath, :line => line)
      abort
    end

    tmp_file = git.show_to_tmp_file(filepath, revision)
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
end