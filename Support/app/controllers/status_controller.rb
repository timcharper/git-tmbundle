class StatusController < ApplicationController
  include SubmoduleHelper
  def index
    file_or_path = params[:path] || git.paths.first
    puts '<h2>Status for ' + file_or_path.map { |e| "‘#{htmlize(shorten(e))}’" }.join(', ') + " on branch ‘#{git.branch && git.branch.current.name}’</h2>"
    status_data = git.status(file_or_path)
    render "_status", :locals => {:status_data => status_data}
    
    git.submodule.all(:path => file_or_path).each do |submodule|
      next if (status_data = submodule.git.status).blank?
      render_submodule_header(submodule)
      render "_status", :locals => {:status_data => status_data, :git => submodule.git}
    end
  end
end