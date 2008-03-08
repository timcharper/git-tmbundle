class MiscController < ApplicationController
  def init
    puts "<h2>Initializing Git Repository in #{ENV['TM_PROJECT_DIRECTORY']}</h2>"
    puts htmlize(git.init(ENV["TM_PROJECT_DIRECTORY"]))
  end
end