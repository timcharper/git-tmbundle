require File.dirname(__FILE__) + '/../../spec_helper'

describe Git::Branch do
  before(:each) do
    Git.reset_mock!
    
    @branch = Git::Branch.new
    Git.command_response["branch", "-r"] = "  origin/master\n  origin/release\n  origin/task"
    Git.command_response["branch"] = "* master\n  task"
  end
  
  include SpecHelpers
  
  describe "when switching branches" do
    before(:each) do
      @request_branch_expectation = lambda { |response|
        TextMate::UI.should_receive(:request_item).with({:prompt=>"Current branch is 'master'.\nSelect a new branch to switch to:", :items=>["master", "task", "origin/master", "origin/release", "origin/task"], :title=>"Switch to Branch"}).and_return(response)
      }
    end
    
    describe "when switching to a local branch" do
      it "should switch to a local branch" do
        @request_branch_expectation.call("task")
        Git.command_response["checkout", "task"] = %{Switched to branch "task"\n}
        output = capture_output do
          @branch.run_switch
        end
        
        output.should include(%{Switched to branch "task"})
      end
      
      it "should alert you if the switch isn't possible because you're in the middle of a merge" do
        @request_branch_expectation.call("task")
        Git.command_response["checkout", "task"] = %{fatal: you need to resolve your current index first\n}
        TextMate::UI.should_receive(:alert).with(:warning, "Error - couldn't switch", "Git said:\nfatal: you need to resolve your current index first\n\nYou're probably in the middle of a conflicted merge, and need to commit", "OK").and_return("Yes")
        @branch.run_switch
      end
      
      it "should ask you if you'd like to force when uncommitted files exist" do
        @request_branch_expectation.call("task")
        Git.command_response["checkout", "task"] = %{fatal: Entry 'branch_spec.rb' not uptodate. Cannot merge.\n}
        TextMate::UI.should_receive(:alert).with(:informational, "Conflict detected if you switch", "There are uncommitted changes that will cause conflicts by this switch (branch_spec.rb).\nSwitch anyways?", "No", "Yes").and_return("Yes")
        
        Git.command_response["checkout", "-m", "task"] = <<-EOF
Auto-merged Support/spec/lib/commands/branch_spec.rb
CONFLICT (content): Merge conflict in Support/spec/lib/commands/branch_spec.rb
M	Support/spec/lib/commands/branch_spec.rb
EOF
        output = capture_output do
          @branch.run_switch
        end
        
        output.should include("CONFLICT (content): Merge conflict in Support/spec/lib/commands/branch_spec.rb")
      end
    end
    
    describe "when switching to a remote branch" do
      before(:each) do
        @get_branch_name_params = {:title=>"Switch to remote branch", :prompt=>"You must set up a local tracking branch to work on 'origin/release'.\nWhat would you like to name the local tracking branch?", :default=>"release"}
      end
      
      it "should switch to a remote branch" do
        @request_branch_expectation.call("origin/release")
        TextMate::UI.should_receive(:request_string).with(@get_branch_name_params).and_return("release")
        Git.command_response["branch", "--track", "release", "origin/release"] = %{Branch release set up to track remote branch refs/remotes/origin/release.\n}
        Git.command_response["checkout", "release"] = %{Switched to branch "release"\n}
        output = capture_output do
          @branch.run_switch
        end
        
        output.should include(%{Branch release set up to track remote branch refs/remotes/origin/release.})
        output.should include(%{Switched to branch "release"})
      end
      
      it "should not allow you to create a branch with an existing local name" do
        @request_branch_expectation.call("origin/release")
        TextMate::UI.should_receive(:request_string).once.with(@get_branch_name_params).and_return("task")
        TextMate::UI.should_receive(:alert).with(:warning, "Branch name already taken!", "The branch name 'task' is already in use.\nVery likely this is the branch you want to work on.\nIf not, pick another name.", "Pick another name", "Switch to it", "Cancel").and_return("Cancel")
        @branch.run_switch
      end
    end
  end
  describe "when deleting branches" do
    before(:each) do
      @request_branch_expectation = lambda { |response|
        TextMate::UI.should_receive(:request_item).with(:title => "Delete Branch", :prompt => "Select the branch to delete:", :items => ["master", "task", "origin/master", "origin/release", "origin/task"]).and_return(response)
      }
    end
    describe "when deleting local branches" do
      before(:each) do
      end
      describe "when branch is not fully merged" do
        before(:each) do
          Git.command_response["branch", "-d", "task"] = "error: branch 'task' is not a strict subset of HEAD\nnot going to allow you to delete it!"
          Git.command_response["branch", "-D", "task"] = "Deleted branch task."
          @really_delete_params = [:warning, "Warning", "Branch 'task' is not a strict subset of your current HEAD (it has unmerged changes)\nReally delete it?", 'Yes', 'No']
        end
      
        it "Ask you if you'd like to delete the branch, and then delete it with -D if yes" do
          @request_branch_expectation.call("task")
          TextMate::UI.should_receive(:alert).with(*@really_delete_params).and_return("Yes")
          TextMate::UI.should_receive(:alert).with(:informational, "Delete branch", "Deleted branch task.", "OK")
          @branch.run_delete
        end
      
        it "allow you to cancel" do
          @request_branch_expectation.call("task")
          TextMate::UI.should_receive(:alert).with(*@really_delete_params).and_return("No")
          @branch.run_delete
        end
      end
    
      describe "when branch is fully merged" do
        before(:each) do
          Git.command_response["branch", "-d", "task"] = "Deleted branch task."
        end
      
        it "should delete" do
          @request_branch_expectation.call("task")
          TextMate::UI.should_receive(:alert).with(:informational, "Success", "Deleted branch task.", "OK").and_return("No")
          @branch.run_delete
        end
      end
    end
  
    describe "when deleting remote branches" do
      it "should delete a remote branch via a push" do
        @request_branch_expectation.call("origin/task")
        Git.command_response["push", "origin", ":task"] = <<EOF
deleting 'refs/heads/task'
 Also local refs/remotes/origin/task
refs/heads/task: d8b368361ebdf2c51b78f7cfdae5c3044b23d189 -> deleted
Everything up-to-date
EOF
      
        TextMate::UI.should_receive(:alert).with(:informational, "Success", "Deleted remote branch origin/task.", "OK").and_return("No")
        @branch.run_delete
      
        Git.commands_ran.should include(["push", "origin", ":task"])
      end
    
      it "should show a message when server reports branch doesn't exist" do
        @request_branch_expectation.call("origin/task")
        Git.command_response["push", "origin", ":task"] = <<EOF
error: dst refspec origin does not match any existing ref on the remote and does not start with refs/.
fatal: The remote end hung up unexpectedly
error: failed to push to '../origin/'
EOF
        TextMate::UI.should_receive(:alert).with(:warning, "Delete branch failed!", "The source 'origin' reported that the branch 'task' does not exist.\nTry running the prune remote stale branches command?", "OK")
        @branch.run_delete
      end
    end
  end
end
