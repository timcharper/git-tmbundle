class StatusController < ApplicationController
  def index
    file_or_path = params[:path] || git.paths.first
    puts '<h2>Status for ' + file_or_path.map { |e| "‘#{htmlize(shorten(e))}’" }.join(', ') + '</h2>'
    @status_data = git.status(file_or_path)
    render "_status", :locals => {:status_data => @status_data}
  end
end