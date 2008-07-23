require File.dirname(__FILE__) + '/../spec_helper'

describe Git::Stash do
  before(:each) do
    Git.reset_mock!
    @stash_controller = StashController.new
    StashController.stub!(:new).and_return(@stash_controller)
  end
  
  include SpecHelpers
  
  it "should ask you if you want to add unstashed files" do
    flush
    TextMate::UI.should_receive(:alert).with(:warning, "Untracked files in working copy", "Would you like to include the following untracked files in your stash?:\nuntracked_file.txt\nother_untracked_file.txt\n", "Add them", "Leave them out", "Cancel").and_return("Add them")
    TextMate::UI.should_receive(:request_string).with({:prompt=>"Describe stash:", :default=>"WIP: ", :title=>"Stash"}).and_return("WIP")
    
    Git.command_response["ls-files", "-o", "--exclude-per-directory=.gitignore"] = "untracked_file.txt\nother_untracked_file.txt\n"
    Git.command_response["stash", "save", "WIP"] = <<-EOF
Saved "mybranch: WIP... msg"
HEAD is now at 7bba918... msg
EOF
    output = capture_output do
      dispatch(:controller => "stash", :action => "save")
    end
    
    output.should include("Saved \"mybranch: WIP")
    Git.commands_ran.should include(["add", "."])
  end
  
  
  describe "when applying a stash" do
    before(:each) do
      @stash_controller.stub!(:select_stash).and_return({:description=>" On master: boogy", :name=>"stash@{0}", :id=>0})
      Git.command_response["stash", "list"] = fixture_file("stash_list_response_many_stashes.txt")
      Git.command_response["stash", "pop", "stash@{0}"] = fixture_file("status_output.txt")
      Git.command_response["stash", "show", "-p", "stash@{0}"] = fixture_file("changed_files.diff")
      @output = capture_output do
        dispatch(:controller => "stash", :action => "pop")
      end
    
      @h = Hpricot(@output)
    end
    
    it "should show the project status" do
      (@h / "table#status_output / tr").length.should == 6
      @output.should include("app/views/layouts/application.html.erb")
    end
    
    it "should show a diff of the stash applied" do
      (@h / "table.codediff").length.should == 2
    end
  end
end
