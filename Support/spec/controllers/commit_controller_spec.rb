require File.dirname(__FILE__) + '/../spec_helper'

describe CommitController do
  include SpecHelpers
  before(:each) do
    @git = Git.new
    @controller = CommitController.new
    Git.stub!(:new).and_return(@git)
    CommitController.stub!(:new).and_return(@controller)
    Git.command_response["status"] = fixture_file("status_output.txt")
  end
  
  describe "normal commit" do
    it "should run a commit" do
      @message = "My commit message"
      @git.should_receive(:merge_message).and_return(nil)
      @controller.stub!(:show_commit_dialog).and_return([@message, ["file1.txt", "file2.txt"]])
      output = capture_output do
        dispatch(:controller => "commit")
      end
      output.should include(@message)
    end
  end
  
  describe "when in the middle of a merge" do
    it "should run the mege dialog" do
      @merge_message = "Merged some branch into another branch..."
      @git.should_receive(:merge_message).twice.and_return(@merge_message)
      output = capture_output do
        dispatch(:controller => "commit")
      end
      output.should include(@merge_message)
    end
  end
  
  describe "when running a merge commit" do
    it "should run" do
      @merge_message = "Merged some branch into another branch..."
      output = capture_output do
        dispatch(:controller => "commit", :action => "merge_commit", :message => @merge_message)
      end
      output.should include(@merge_message)
    end
  end
end
