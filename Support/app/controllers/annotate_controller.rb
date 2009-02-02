# encoding: utf-8

class AnnotateController < ApplicationController
  include DateHelpers
  layout "application", :except => "update"
  def index
    @file_path = params[:file_path] || ENV['TM_FILEPATH']
    @annotations = git.annotate(@file_path)

    if @annotations.nil?
      puts "Error.  Aborting"
      abort
    end

    @log_entries = git.log(:path => @file_path)
    render "index"
  end
  
  def update
    file_path = ENV['TM_FILEPATH']
    revision = params[:revision]

    @annotations = git.annotate(file_path, revision)

    if @annotations.nil?
      puts "Error.  Aborting"
      abort
    end
    
      # f = Formatters::Annotate.new(:selected_revision => revision, :as_partial => true)
      # f.header "Annotations for ‘#{htmlize(shorten(file_path))}’"
      # f.content annotations
     render "_content", :locals => { :annotations => @annotations, :revision => revision } 
     render "_select_revision", :locals => { :revision => revision}
  end
end