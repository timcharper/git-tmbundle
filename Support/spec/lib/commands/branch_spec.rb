require File.dirname(__FILE__) + '/../../spec_helper'

describe SCM::Git::Branch do
  before(:each) do
    @git = Git.new
    Git.reset_mock!
  end
  
  include SpecHelpers
  
  it "should list ignore (no branch)" do
    Git.command_response["branch"] = <<EOF
* (no branch)
  test_mod
EOF
    
    @git.branch.list_names.should == ["test_mod"]
  end
  
  describe "listing branches" do
    before(:each) do
      Git.command_response["branch"] = <<EOF
* test_mod
  master
EOF
      Git.command_response["branch", "-r"] = <<EOF
  origin/alpha
  origin/test_mod
  origin/master
EOF
    end
    
    it "should return a list of branches" do
      @git.branch.all.should have(5).branches
    end
    
    it "should filter to the remote branches" do
      @git.branch.all(:remote).should have(3).branches
    end
    
    it "should filter to the local branches" do
      @git.branch.all(:local).should have(2).branches
    end
  end
end
