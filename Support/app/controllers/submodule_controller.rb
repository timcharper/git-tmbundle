require LIB_ROOT + '/ui.rb'

class SubmoduleController < ApplicationController
  def index
    @submodules = git.submodule.all
    render "index"
  end
  
  def add
    repository_path = TextMate::UI.request_string(:title => "Add submodule", :prompt => "Enter the submodule clone URL")
    if repository_path.nil?
      puts "Canceled"
      return
    end
    
    parent_folder = TextMate::UI.request_directory("Select the parent folder for the submodule:", :initial_directory => git.git_base)
    if parent_folder.nil?
      puts "Canceled"
      return
    end
    
    /([^\/]+?)(.git){0,1}$/.match(repository_path)
    module_name = TextMate::UI.request_string(:title => "What do you want to call the module (will be the folder name)?", :default => $1 )
    
    if module_name.nil?
      puts "Canceled"
      return
    end
    
    puts "<pre>"
    git.submodule.add(repository_path, File.join(parent_folder, module_name))
    puts "</pre>"
    # `CocoaDialog fileselect ‑‑select‑only‑directories`
    
  end
end 