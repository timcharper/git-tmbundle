require File.dirname(__FILE__) + '/../spec_helper'

describe "deleting branches locally warns and allows you to cancel", :shared => true do
  it "Ask you if you'd like to delete the branch, and then delete it with -D if yes" do
    @set_branch_to_choose.call("task")
    TextMate::UI.should_receive(:alert).with(:informational, "Deleted branch", "Deleted branch task.", "OK")
    TextMate::UI.should_receive(:alert).with(*@really_delete_params).and_return("Yes")
    dispatch(:controller => "branch", :action => "delete")
  end

  it "allow you to cancel" do
    @set_branch_to_choose.call("task")
    TextMate::UI.should_receive(:alert).with(*@really_delete_params).and_return("No")
    dispatch(:controller => "branch", :action => "delete")
  end
end


describe "deleting branches remotely recognizes success and failure responses", :shared => true do
  it "should delete a remote branch via a push" do
    @set_branch_to_choose.call("origin/task")
    Git.command_response["push", "origin", ":task"] = @success_delete_response

    TextMate::UI.should_receive(:alert).with(:informational, "Success", "Deleted remote branch origin/task.", "OK").and_return("No")
    dispatch(:controller => "branch", :action => "delete")

    Git.commands_ran.should include(["push", "origin", ":task"])
  end
  
  it "should show a message when server reports branch doesn't exist" do
    @set_branch_to_choose.call("origin/task")
    Git.command_response["push", "origin", ":task"] = @failure_delete_response
    TextMate::UI.should_receive(:alert).with(:warning, "Delete branch failed!", "The source 'origin' reported that the branch 'task' does not exist.\nTry running the prune remote stale branches command?", "OK")
    dispatch(:controller => "branch", :action => "delete")
  end
end

describe BranchController do
  before(:each) do
    @git = Git.singleton_new
    Git.reset_mock!
    Git.command_response["branch", "-r"] = "  origin/master\n  origin/release\n  origin/task"
    Git.command_response["branch"] = "* master\n  task"
  end
  
  include SpecHelpers
  
  describe "when switching branches" do
    before(:each) do
      @set_branch_to_choose = lambda { |response|
        TextMate::UI.should_receive(:request_item).with({:prompt=>"Current branch is 'master'.\nSelect a new branch to switch to:", :items=>["master", "task", "origin/master", "origin/release", "origin/task"], :title=>"Switch to Branch", :force_pick => true}).and_return(response)
      }
    end
    
    describe "when switching to a local branch" do
      it "should switch to a local branch" do
        @set_branch_to_choose.call("task")
        Git.command_response["checkout", "task"] = %{Switched to branch "task"\n}
        output = capture_output do
          dispatch(:controller => "branch", :action => "switch")
        end
        
        output.should include(%{Switched to branch "task"})
      end
      
      it "should alert you if the switch isn't possible because you're in the middle of a merge" do
        @set_branch_to_choose.call("task")
        Git.command_response["checkout", "task"] = %{fatal: you need to resolve your current index first\n}
        TextMate::UI.should_receive(:alert).with(:warning, "Error - couldn't switch", "Git said:\nfatal: you need to resolve your current index first\n\nYou're probably in the middle of a conflicted merge, and need to commit", "OK").and_return("Yes")
        dispatch(:controller => "branch", :action => "switch")
      end
      
      it "should ask you if you'd like to force when uncommitted files exist" do
        @set_branch_to_choose.call("task")
        Git.command_response["checkout", "task"] = %{error: Entry 'branch_spec.rb' not uptodate. Cannot merge.\n}
        TextMate::UI.should_receive(:alert).with(:informational, "Conflicts may happen if you switch", "There are uncommitted changes that might cause conflicts by this switch (branch_spec.rb).\nSwitch anyways?", "No", "Yes").and_return("Yes")
        
        Git.command_response["checkout", "-m", "task"] = <<-EOF
Auto-merged Support/spec/lib/commands/branch_spec.rb
CONFLICT (content): Merge conflict in Support/spec/lib/commands/branch_spec.rb
M	Support/spec/lib/commands/branch_spec.rb
EOF
        output = capture_output do
          dispatch(:controller => "branch", :action => "switch")
        end
        
        output.should include("CONFLICT (content): Merge conflict in Support/spec/lib/commands/branch_spec.rb")
      end
      
      describe "when you have submodules" do
        it "should with_submodule_updating" do
          @set_branch_to_choose.call("task")
          
          git = Git.singleton_new
          @submodule = stub("submodule", :cache => true, :restore => true, :path => "path/to/module", :modified? => false)
          git.submodule.should_receive(:all).any_number_of_times.and_return([@submodule])
          output = capture_output do
            dispatch(:controller => "branch", :action => "switch")
          end
        end
      end
    end
    
    describe "when switching to a remote branch" do
      before(:each) do
        @get_branch_name_params = {:title=>"Switch to remote branch", :prompt=>"You must set up a local tracking branch to work on 'origin/release'.\nWhat would you like to name the local tracking branch?", :default=>"release"}
      end
      
      it "should switch to a remote branch" do
        @set_branch_to_choose.call("origin/release")
        TextMate::UI.should_receive(:request_string).with(@get_branch_name_params).and_return("release")
        Git.command_response["branch", "--track", "release", "origin/release"] = %{Branch release set up to track remote branch refs/remotes/origin/release.\n}
        Git.command_response["checkout", "release"] = %{Switched to branch "release"\n}
        @git.submodule.stub!(:all).and_return([])
        output = capture_output do
          dispatch(:controller => "branch", :action => "switch")
        end
        
        output.should include(%{Branch release set up to track remote branch refs/remotes/origin/release.})
        output.should include(%{Switched to branch "release"})
      end
      
      it "should not allow you to create a branch with an existing local name" do
        @set_branch_to_choose.call("origin/release")
        TextMate::UI.should_receive(:request_string).once.with(@get_branch_name_params).and_return("task")
        TextMate::UI.should_receive(:alert).with(:warning, "Branch name already taken!", "The branch name 'task' is already in use.\nVery likely this is the branch you want to work on.\nIf not, pick another name.", "Pick another name", "Switch to it", "Cancel").and_return("Cancel")
        dispatch(:controller => "branch", :action => "switch")
      end
    end
    
    describe "when merging" do
      before(:each) do
        @git = Git.singleton_new
        @controller = BranchController.singleton_new
        @git.branch.stub!(:current_name).and_return("master")
        @git.branch.stub!(:list_names).and_return(["master", "release", "old_skool"])
        
        TextMate::UI.should_receive(:request_item).with(:title => "Merge", :prompt => "Merge which branch into 'master':", :items => ["release", "old_skool"], :force_pick => true).and_return("release")
      end
      
      it "should merge a branch" do
        @git.should_receive(:merge).with("release").and_return({:text => "Success!", :conflicts => [] })
        output = capture_output do
          dispatch(:controller => "branch", :action => "merge")
        end
        
        output.should include("Success!")
      end
      
      it "should run with_submodule_updating" do
        @controller.should_receive(:with_submodule_updating)
        capture_output { dispatch(:controller => "branch", :action => "merge") }
      end
    end
  end
  
  describe "when deleting branches" do
    before(:each) do
      @set_branch_to_choose = lambda { |response|
        TextMate::UI.should_receive(:request_item).with(:title => "Delete Branch", :prompt => "Select the branch to delete:", :items => ["master", "task", "origin/master", "origin/release", "origin/task"]).and_return(response)
      }
    end
    describe "locally" do
      describe "when branch is not fully merged" do
        before(:each) do
          Git.command_response["branch", "-d", "task"] = "error: branch 'task' is not a strict subset of HEAD\nnot going to allow you to delete it!"
          Git.command_response["branch", "-D", "task"] = "Deleted branch task."
          @really_delete_params = [:warning, "Warning", "Branch 'task' is not an ancestor of your current HEAD (it has unmerged changes)\nReally delete it?", 'Yes', 'No']
        end
        
        describe "Git 1.5.3.4" do
          before(:each) do
            Git.command_response["branch", "-d", "task"] = "error: branch 'task' is not a strict subset of HEAD\nnot going to allow you to delete it!"
          end
          
          it_should_behave_like "deleting branches locally warns and allows you to cancel"
        end
        
        describe "Git 1.5.3.4" do
          before(:each) do
            Git.command_response["branch", "-d", "task"] = "error: The branch 'fixtures' is not an ancestor of your current HEAD.\nIf you are sure you want to delete it, run 'git branch -D fixtures'."
          end
          
          it_should_behave_like "deleting branches locally warns and allows you to cancel"
        end
      end
    
      describe "when branch is fully merged" do
        before(:each) do
          Git.command_response["branch", "-d", "task"] = "Deleted branch task."
        end
      
        it "should delete" do
          @set_branch_to_choose.call("task")
          TextMate::UI.should_receive(:alert).with(:informational, "Success", "Deleted branch task.", "OK").and_return("No")
          dispatch(:controller => "branch", :action => "delete")
        end
      end
    end
    
    describe "creating a branch" do
      it "should run" do
        TextMate::UI.should_receive(:request_string).with(:title => "Create Branch", :prompt => "Enter the name of the new branch:").and_return("task")
        Git.command_response["checkout", "-b", "task"] = %{Switched to a new branch "tt"\n}
        output = capture_output do
          dispatch(:controller => "branch", :action => "create")
        end
        output.should == %{Switched to a new branch "tt"\n}
      end
    end
    
    describe "remotely" do
      describe "git 1.5.3" do
        before(:each) do
          @success_delete_response = <<EOF
deleting 'refs/heads/task'
 Also local refs/remotes/origin/task
refs/heads/task: d8b368361ebdf2c51b78f7cfdae5c3044b23d189 -> deleted
Everything up-to-date
EOF
          @failure_delete_response = <<EOF
error: dst refspec origin does not match any existing ref on the remote and does not start with refs/.
fatal: The remote end hung up unexpectedly
error: failed to push to '../origin/'
EOF
        end
        
        it_should_behave_like "deleting branches remotely recognizes success and failure responses"
      end
      
      describe "git 1.5.4.3" do
        before(:each) do
          @success_delete_response = <<EOF
To ../origin/
 - [deleted]         boogy
EOF
          @failure_delete_response = <<EOF
error: dst refspec task does not match any existing ref on the remote and does not start with refs/.
fatal: The remote end hung up unexpectedly
error: failed to push some refs to '../origin/'
EOF
        end
        
        it_should_behave_like "deleting branches remotely recognizes success and failure responses"
      end
    end
  end
end

