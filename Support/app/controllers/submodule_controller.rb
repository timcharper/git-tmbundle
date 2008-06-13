require LIB_ROOT + '/ui.rb'

class SubmoduleController < ApplicationController
  def index
    render "index"
  end
  
  def list
    @submodules = git.submodule.all
    render "list"
  end
  
  def add
    (repository_path = prompt_repository_path) &&
    (parent_folder = prompt_parent_folder) &&
    (module_name = prompt_module_name(repository_path)) ||
      (cancel and return)
    
    # This is messy, but I'm not entirely sure what is going to happen with this yet (there may be some parsing going on that will require interaction between the view and the controller)
    puts "<pre>"
      stream = git.submodule.add(repository_path, File.join(parent_folder, module_name))
      stream.pipe_to(STDOUT)
    puts "</pre>"
    
    puts htmlize(git.submodule.init_and_update)
    
    puts <<-EOF
<p>Done.</p>
EOF
    rescan_project
  end
  
  def update
    puts "<pre>"
    puts git.submodule.init_and_update
    puts "</pre>"
  end
  
  #
  ##
  ###
  protected
    def prompt_repository_path
      TextMate::UI.request_string(:title => "Add submodule", :prompt => "Enter the submodule clone URL")
    end
    
    def prompt_parent_folder
      TextMate::UI.request_directory("Select the parent folder for the submodule:", :initial_directory => git.path)
    end
    
    def prompt_module_name(repository_path = "")
      /([^\/]+?)(.git){0,1}$/.match(repository_path)
      module_name = TextMate::UI.request_string(:title => "What do you want to call the module (will be the folder name)?", :default => $1 )
    end
    
    def cancel
      puts "Canceled"
      true
    end
end 