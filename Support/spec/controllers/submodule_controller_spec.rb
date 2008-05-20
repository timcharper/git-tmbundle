require File.dirname(__FILE__) + '/../spec_helper'

describe SubmoduleController do
  include SpecHelpers
  include Parsers
  
  before(:each) do
    @git = Git.singleton_new
    @controller = SubmoduleController.singleton_new
    
    @module_repo_path = "git@server:/path/to/my-module.git"
    @module_name = "my-module"
  end
  
  # TextMate::UI.should_receive(:request_string).with(
  #   :title => "Add submodule", :prompt => "Enter the submodule clone URL"
  # ).and_return(@module_repo_path)
  
  # TextMate::UI.should_receive(:request_directory).with(
  #   "Select the parent folder for the submodule:", :initial_directory => @git.path
  # ).and_return("/base/")
  
  it "should extract an intelligent default" do
    TextMate::UI.should_receive(:request_string).with(
      :title => "What do you want to call the module (will be the folder name)?", :default => "my-module"
    ).and_return(@module_name)
    @controller.send(:prompt_module_name, @module_repo_path)
  end
  
  it "should add a repository and output the results of the add / initialize" do
    @controller.should_receive(:prompt_repository_path).and_return(@module_repo_path)
    @controller.should_receive(:prompt_parent_folder).and_return(@git.path)
    @controller.should_receive(:prompt_module_name).and_return(@module_name)
    
    @git.submodule.should_receive(:add).with(@module_repo_path, File.join("/base/", @module_name)).and_return(StringIO.new("Added!"))
    @git.submodule.should_receive(:init_and_update).and_return("Initialized!")
    
    output = capture_output do
      dispatch(:controller => "submodule", :action => "add")
    end
    
    output.should include("Added!")
    output.should include("Initialized!")
    # puts "<pre>#{output}</pre>"
  end
end