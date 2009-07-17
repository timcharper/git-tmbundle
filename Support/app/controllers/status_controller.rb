# encoding: utf-8
require LIB_ROOT + '/ui.rb'

class StatusController < ApplicationController
  layout "application", :except => [:edit_conflicted_file]

  include SubmoduleHelper
  def index
    file_or_path = *(params[:path] || git.paths.first)
    puts '<h2>Status for ' + file_or_path.map { |e| "‘#{htmlize(shorten(e))}’" }.join(', ') + " on branch ‘#{git.branch.current_name}’</h2>"
    status_data = git.status(file_or_path)
    render "_status", :locals => {:status_data => status_data}
    
    git.submodule.all(:path => file_or_path).each do |submodule|
      next if (status_data = submodule.git.status).blank?
      render_submodule_header(submodule)
      render "_status", :locals => {:status_data => status_data, :git => submodule.git}
    end
  end

  def edit_conflicted_file
    file_or_path = git.path
    conflicts = git.status(file_or_path).select { |file_status| file_status[:status][:short] == "C" }
    if conflicts.empty?
      puts "No conflicted files"
      exit_show_tool_tip
    end
    index = TextMate::UI.menu(conflicts.map { |conflict| conflict[:display] })
    tm_open(conflicts[index][:path]) if index
    exit_discard
  end
end