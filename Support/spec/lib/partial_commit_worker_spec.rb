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
end
