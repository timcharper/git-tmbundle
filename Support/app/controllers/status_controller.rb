class StatusController < ApplicationController
  def index
    file_or_path = params[:file_or_path] || git.paths.first
    puts '<h2>Status for ' + file_or_path.map { |e| "‘#{htmlize(shorten(e))}’" }.join(', ') + '</h2>'
    puts '<pre>'
    git.status(file_or_path).each do |e|
      puts "<span title='#{htmlize(e[:status][:long])}'>#{htmlize(e[:status][:short])}</span> <a href='txmt://open?url=file://#{e_url e[:path]}'>#{htmlize(e[:display])}</a>"
    end
    puts "</pre>"
  end
  
end