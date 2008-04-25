require File.dirname(__FILE__) + '/../spec_helper'
require LIB_ROOT + "/partial_commit_worker"

describe PartialCommitWorker do
  before(:each) do
    @git = Git.singleton_new
  end
  
  it "should NOT be OK to proceed when not on a branch but performing an initial commit" do
    @git.branch.should_receive(:current_name).and_return(nil)
    @git.should_receive(:initial_commit_pending?).and_return(false)
    PartialCommitWorker::Base.new(@git).ok_to_proceed_with_partial_commit?.should == false
  end
  
  it "should be OK to proceed when not on a branch but performing an initial commit" do
    @git.branch.should_receive(:current_name).and_return(nil)
    @git.should_receive(:initial_commit_pending?).and_return(true)
    PartialCommitWorker::Base.new(@git).ok_to_proceed_with_partial_commit?.should == true
  end
  
  describe "Amend" do
    before(:each) do
      @amend = PartialCommitWorker::Amend.new(@git)
    end
    
    it "should use the last log message when 'log message' not checked" do
      @git.stub!(:log).and_return([{:msg => "My Message"}])
      @amend.stub!(:exec_commit_dialog).and_return([false, "", ["file.txt"]])
      @amend.show_commit_dialog.should == ["My Message", ["file.txt"]]
    end
  end
  
end
