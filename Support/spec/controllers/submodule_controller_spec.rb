require File.dirname(__FILE__) + '/../spec_helper'

describe SubmoduleController do
  include SpecHelpers
  include Parsers
  
  before(:each) do
    
  end
  
  it "should add a repository" do
    module_repo_path = "git@server:/path/to/my-module.git"
    module_name = "my-module"
    
    git = Git.singleton_git
    
    TextMate::UI.should_receive(:request_string).with(
      :title => "Add submodule", :prompt => "Enter the submodule clone URL"
    ).and_return(module_repo_path)
    
    TextMate::UI.should_receive(:request_directory).with(
      "Select the parent folder for the submodule:", :initial_directory => git.git_base
    ).and_return("/base/")
    
    TextMate::UI.should_receive(:request_string).with(
      :title => "What do you want to call the module (will be the folder name)?", :default => "my-module"
    ).and_return(module_name)
    
    git.submodule.should_receive(:add).with(module_repo_path, File.join("/base/", module_name)).and_return(StringIO.new("Added!"))
    git.submodule.should_receive(:init_and_update).and_return("")
    
    output = capture_output do
      dispatch(:controller => "submodule", :action => "add")
    end
    
    output.should include("Added!")
    # puts "<pre>#{output}</pre>"
  end
end