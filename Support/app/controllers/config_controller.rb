class ConfigController < ApplicationController
  include ConfigHelper
  def index
    render "index"
  end
  
  def set
    value = params[:value]
    git.config[(params[:scope] || "local"), params[:key]] = params[:value]
  end
end