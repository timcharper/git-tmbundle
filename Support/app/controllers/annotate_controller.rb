class AnnotateController < ApplicationController
  include DateHelpers
  layout "application", :except => "update"
  def index
    log = SCM::Git::Log.new

    @filepath = params[:filepath] || ENV['TM_FILEPATH']
    @annotations = git.annotate(@filepath)

    if @annotations.nil?
      puts "Error.  Aborting"
      abort
    end

    @log_entries = log.log(@filepath)
    render "index"
  end
  
  def update
    filepath = ENV['TM_FILEPATH']
    revision = params[:revision]

    @annotations = git.annotate(filepath, revision)

    if @annotations.nil?
      puts "Error.  Aborting"
      abort
    end
    
      # f = Formatters::Annotate.new(:selected_revision => revision, :as_partial => true)
      # f.header "Annotations for ‘#{htmlize(shorten(filepath))}’"
      # f.content annotations
     render "_content", :locals => { :annotations => @annotations, :revision => revision } 
     render "_select_revision", :locals => { :revision => revision}
  end
end