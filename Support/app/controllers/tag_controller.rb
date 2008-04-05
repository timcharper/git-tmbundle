require ENV['TM_SUPPORT_PATH'] + '/lib/ui.rb'

class TagController < ApplicationController
  def create
    if ! (name = prompt_tag_name)
      puts "Aborted"
      return
    end
    
    if git.create_tag(name) == true
      puts "Tag #{name} created"
      flush
      render_component(:controller => "remote", :action => "push_tag", :tag => name) if prompt_want_to_push_remote
    end
  end
  
  def prompt_tag_name
    TextMate::UI.request_string(:title => "Create Tag", :prompt => "Enter the name of the new tag:")
  end
  
  def prompt_want_to_push_remote
    TextMate::UI.alert(:warning, "Push tag to remote servers", "Would you like to push this tag to your remote repository(s)", 'Yes', 'No') == "Yes"
  end
  
end