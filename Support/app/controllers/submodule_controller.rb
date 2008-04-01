class SubmoduleController < ApplicationController
  def index
    @submodules = git.submodule.all
    render "index"
    
  end
end