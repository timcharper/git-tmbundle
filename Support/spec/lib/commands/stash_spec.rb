require File.dirname(__FILE__) + '/../../spec_helper'

describe Git::Stash do
  before(:each) do
    Git.reset_mock!
    
    @stash = Git::Stash.new
    # Git.command_response["branch", "-r"] = "  origin/master\n  origin/release\n  origin/task"
    # Git.command_response["branch"] = "* master\n  task"
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
      @stash.run_stash_save
    end
    
    output.should include("Saved \"mybranch: WIP")
    Git.commands_ran.should include(["add", "."])
  end
end
